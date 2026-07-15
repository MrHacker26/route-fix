import '../../../core/abstractions/result.dart';
import '../../../core/errors/app_failure.dart';
import '../../models/dns_lookup_result.dart';
import '../../models/ipv4_connectivity_result.dart';
import '../../models/ipv6_connectivity_result.dart';
import '../../models/probe_stage.dart';

/// Shared evidence checks for diagnosis rule evaluation.
///
/// Keeps recommendation gating consistent across rules. No networking.
abstract final class DiagnosisEvidence {
  /// Minimum confidence required before attaching a fix recommendation.
  static const double highConfidenceFloor = 0.85;

  /// IPv6 must be at least this multiple of IPv4 latency to count as slower.
  static const double ipv6SlowdownRatio = 3.0;

  /// Absolute floor so tiny IPv4 baselines do not trigger Prefer IPv4 alone.
  static const Duration ipv6AbsoluteSlowFloor = Duration(milliseconds: 200);

  /// [UnknownFailure] / [CancellationFailure] are never enough for a fix.
  static bool isGenericFailure(AppFailure? failure) {
    return failure is UnknownFailure || failure is CancellationFailure;
  }

  /// Whether confidence is high enough to attach a recommendation.
  static bool isHighConfidence(double confidence) {
    return confidence >= highConfidenceFloor;
  }

  /// DNS resolved at least one address.
  static bool dnsSucceeded(Result<DnsLookupResult> dnsLookup) {
    return switch (dnsLookup) {
      Success(:final value) =>
        value.ipv4Addresses.isNotEmpty || value.ipv6Addresses.isNotEmpty,
      Failure() => false,
    };
  }

  /// Prefer IPv4 / Disable IPv6 is justified only with dual-stack contrast.
  ///
  /// Requires:
  /// - DNS succeeded
  /// - IPv4 succeeded
  /// - IPv6 consistently fails (typed) **or** is significantly slower
  /// - No generic IPv6 failure
  static bool canRecommendPreferIpv4({
    required Result<DnsLookupResult> dnsLookup,
    required Ipv4ConnectivityResult ipv4,
    required Ipv6ConnectivityResult ipv6,
  }) {
    if (!dnsSucceeded(dnsLookup)) return false;
    if (!ipv4.success) return false;
    if (isGenericFailure(ipv6.failure)) return false;

    if (!ipv6.success) {
      return _isSpecificIpv6PathFailure(ipv6);
    }

    final ipv4Latency = ipv4.latency;
    final ipv6Latency = ipv6.latency;
    if (ipv4Latency == null || ipv6Latency == null) return false;
    if (ipv4Latency <= Duration.zero) return false;

    final slowerThanRatio =
        ipv6Latency >= ipv4Latency * ipv6SlowdownRatio;
    final aboveAbsoluteFloor = ipv6Latency >= ipv6AbsoluteSlowFloor;
    return slowerThanRatio && aboveAbsoluteFloor;
  }

  /// Typed IPv6 path failure (not a blurry generic error).
  static bool _isSpecificIpv6PathFailure(Ipv6ConnectivityResult ipv6) {
    final failure = ipv6.failure;
    if (failure == null) return false;
    if (isGenericFailure(failure)) return false;

    if (failure is TCPFailure) return true;
    if (failure is DNSFailure) return true;
    if (failure is TimeoutFailure) {
      return ipv6.stageFailed == ProbeStage.dns ||
          ipv6.stageFailed == ProbeStage.tcp;
    }
    return false;
  }
}
