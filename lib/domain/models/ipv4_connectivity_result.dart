import '../../core/errors/app_failure.dart';

/// Outcome of an IPv4 connectivity check against a hostname.
class Ipv4ConnectivityResult {
  const Ipv4ConnectivityResult({
    required this.success,
    this.latency,
    this.resolvedAddress,
    this.failure,
  });

  final bool success;
  final Duration? latency;
  final String? resolvedAddress;

  /// Structured failure when [success] is false.
  final AppFailure? failure;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}
