import 'dart:async';
import 'dart:io';

import '../../../core/abstractions/result.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/models/dns_lookup_result.dart';
import '../../../domain/services/dns_lookup_service.dart';

/// DNS hostname resolution via `dart:io` [InternetAddress.lookup].
class DartIoDnsLookupService implements DnsLookupService {
  const DartIoDnsLookupService();

  @override
  Future<Result<DnsLookupResult>> lookup(String hostname) async {
    final host = hostname.trim();
    if (host.isEmpty) {
      return const Failure(UnexpectedFailure('Hostname must not be empty'));
    }

    final stopwatch = Stopwatch()..start();

    try {
      final ipv4Future = _lookupFamily(host, InternetAddressType.IPv4);
      final ipv6Future = _lookupFamily(host, InternetAddressType.IPv6);
      final results = await Future.wait<List<String>>([
        ipv4Future,
        ipv6Future,
      ]).timeout(const Duration(seconds: 10));

      stopwatch.stop();

      final ipv4 = results[0];
      final ipv6 = results[1];

      if (ipv4.isEmpty && ipv6.isEmpty) {
        return Failure(
          UnavailableFailure('No addresses found for "$host"'),
        );
      }

      return Success(
        DnsLookupResult(
          hostname: host,
          ipv4Addresses: List.unmodifiable(ipv4),
          ipv6Addresses: List.unmodifiable(ipv6),
          lookupDuration: stopwatch.elapsed,
        ),
      );
    } on TimeoutException {
      stopwatch.stop();
      return const Failure(TimeoutFailure('DNS lookup timed out'));
    } on SocketException catch (error) {
      stopwatch.stop();
      return Failure(
        UnavailableFailure(
          error.message.isEmpty ? 'DNS lookup failed' : error.message,
        ),
      );
    } on ArgumentError catch (error) {
      stopwatch.stop();
      return Failure(UnexpectedFailure('${error.message}'));
    } catch (error) {
      stopwatch.stop();
      return Failure(UnexpectedFailure(error.toString()));
    }
  }

  /// Returns addresses for [type], or an empty list when that family has no records.
  Future<List<String>> _lookupFamily(
    String host,
    InternetAddressType type,
  ) async {
    try {
      final addresses = await InternetAddress.lookup(host, type: type);
      return addresses
          .where((address) => address.type == type)
          .map((address) => address.address)
          .toList(growable: false);
    } on SocketException {
      return const [];
    }
  }
}
