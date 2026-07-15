import 'dart:async';
import 'dart:io';

import '../../../core/abstractions/result.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/models/dns_lookup_result.dart';
import '../../../domain/models/probe_stage.dart';
import '../../../domain/services/dns_lookup_service.dart';
import '../probe_failure_mapper.dart';

/// DNS hostname resolution via `dart:io` [InternetAddress.lookup].
class DartIoDnsLookupService implements DnsLookupService {
  const DartIoDnsLookupService({
    this.timeout = const Duration(seconds: 10),
  });

  final Duration timeout;

  @override
  Future<Result<DnsLookupResult>> lookup(String hostname) async {
    final host = hostname.trim();
    if (host.isEmpty) {
      return const Failure(UnknownFailure('Hostname must not be empty'));
    }

    final stopwatch = Stopwatch()..start();

    try {
      final ipv4Future = _lookupFamily(host, InternetAddressType.IPv4);
      final ipv6Future = _lookupFamily(host, InternetAddressType.IPv6);
      final results =
          await Future.wait<({List<String> addresses, AppFailure? failure})>([
        ipv4Future,
        ipv6Future,
      ]).timeout(timeout);

      stopwatch.stop();

      final ipv4 = results[0].addresses;
      final ipv6 = results[1].addresses;
      final dnsFailure = results[0].failure ?? results[1].failure;

      if (ipv4.isEmpty && ipv6.isEmpty) {
        final failure = dnsFailure ?? DNSFailure('No addresses found for "$host"');
        return Failure(failure);
      }

      return Success(
        DnsLookupResult(
          hostname: host,
          ipv4Addresses: List.unmodifiable(ipv4),
          ipv6Addresses: List.unmodifiable(ipv6),
          lookupDuration: stopwatch.elapsed,
          stageReached: ProbeStage.dns,
        ),
      );
    } on TimeoutException {
      stopwatch.stop();
      return const Failure(TimeoutFailure('DNS lookup timed out'));
    } on SocketException catch (error) {
      stopwatch.stop();
      return Failure(
        ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.dns,
        ),
      );
    } on ArgumentError catch (error) {
      stopwatch.stop();
      return Failure(UnknownFailure('${error.message}'));
    } catch (error) {
      stopwatch.stop();
      return Failure(ProbeFailureMapper.unknown(error));
    }
  }

  /// Returns addresses for [type], capturing DNS failures without swallowing them.
  Future<({List<String> addresses, AppFailure? failure})> _lookupFamily(
    String host,
    InternetAddressType type,
  ) async {
    try {
      final addresses = await InternetAddress.lookup(host, type: type);
      return (
        addresses: addresses
            .where((address) => address.type == type)
            .map((address) => address.address)
            .toList(growable: false),
        failure: null,
      );
    } on SocketException catch (error) {
      return (
        addresses: const <String>[],
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.dns,
        ),
      );
    }
  }
}
