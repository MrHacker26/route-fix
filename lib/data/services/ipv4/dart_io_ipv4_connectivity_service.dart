import 'dart:async';
import 'dart:io';

import '../../../core/errors/app_failure.dart';
import '../../../domain/models/ipv4_connectivity_result.dart';
import '../../../domain/services/ipv4_connectivity_service.dart';
import '../probe_failure_mapper.dart';

/// IPv4 reachability via DNS lookup + TCP connect (`dart:io`).
class DartIoIpv4ConnectivityService implements Ipv4ConnectivityService {
  const DartIoIpv4ConnectivityService({
    this.timeout = const Duration(seconds: 8),
  });

  final Duration timeout;

  @override
  Future<Ipv4ConnectivityResult> check(
    String hostname, {
    int port = 443,
  }) async {
    final host = hostname.trim();
    if (host.isEmpty) {
      return const Ipv4ConnectivityResult(
        success: false,
        failure: UnknownFailure('Hostname must not be empty'),
      );
    }

    if (port < 1 || port > 65535) {
      return const Ipv4ConnectivityResult(
        success: false,
        failure: UnknownFailure('Port must be between 1 and 65535'),
      );
    }

    late final InternetAddress address;
    try {
      final addresses = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv4,
      ).timeout(timeout);

      final ipv4 = addresses
          .where((item) => item.type == InternetAddressType.IPv4)
          .toList(growable: false);

      if (ipv4.isEmpty) {
        return Ipv4ConnectivityResult(
          success: false,
          failure: DNSFailure('No IPv4 address found for "$host"'),
        );
      }

      address = ipv4.first;
    } on TimeoutException {
      return const Ipv4ConnectivityResult(
        success: false,
        failure: TimeoutFailure('IPv4 DNS lookup timed out'),
      );
    } on SocketException catch (error) {
      return Ipv4ConnectivityResult(
        success: false,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeSocketStage.dns,
        ),
      );
    } catch (error) {
      return Ipv4ConnectivityResult(
        success: false,
        failure: ProbeFailureMapper.unknown(error),
      );
    }

    final stopwatch = Stopwatch()..start();
    Socket? socket;

    try {
      socket = await Socket.connect(
        address,
        port,
        timeout: timeout,
      );
      stopwatch.stop();

      return Ipv4ConnectivityResult(
        success: true,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
      );
    } on TimeoutException {
      stopwatch.stop();
      return Ipv4ConnectivityResult(
        success: false,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
        failure: const TimeoutFailure('IPv4 connect timed out'),
      );
    } on SocketException catch (error) {
      stopwatch.stop();
      return Ipv4ConnectivityResult(
        success: false,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeSocketStage.tcp,
        ),
      );
    } catch (error) {
      stopwatch.stop();
      return Ipv4ConnectivityResult(
        success: false,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
        failure: ProbeFailureMapper.unknown(error),
      );
    } finally {
      await socket?.close();
    }
  }
}
