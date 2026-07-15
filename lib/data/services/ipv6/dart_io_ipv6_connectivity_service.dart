import 'dart:async';
import 'dart:io';

import '../../../core/errors/app_failure.dart';
import '../../../domain/models/ipv6_connectivity_result.dart';
import '../../../domain/models/probe_stage.dart';
import '../../../domain/models/probe_timings.dart';
import '../../../domain/services/ipv6_connectivity_service.dart';
import '../probe_failure_mapper.dart';

/// IPv6 reachability via explicit DNS then TCP stages (`dart:io`).
class DartIoIpv6ConnectivityService implements Ipv6ConnectivityService {
  const DartIoIpv6ConnectivityService({
    this.timeout = const Duration(seconds: 8),
  });

  final Duration timeout;

  @override
  Future<Ipv6ConnectivityResult> check(
    String hostname, {
    int port = 443,
  }) async {
    final host = hostname.trim();
    if (host.isEmpty) {
      return const Ipv6ConnectivityResult(
        success: false,
        failure: UnknownFailure('Hostname must not be empty'),
      );
    }

    if (port < 1 || port > 65535) {
      return const Ipv6ConnectivityResult(
        success: false,
        failure: UnknownFailure('Port must be between 1 and 65535'),
      );
    }

    var timings = ProbeTimings.empty;

    final dnsWatch = Stopwatch()..start();
    late final InternetAddress address;
    try {
      final addresses = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv6,
      ).timeout(timeout);

      final ipv6 = addresses
          .where((item) => item.type == InternetAddressType.IPv6)
          .toList(growable: false);

      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);

      if (ipv6.isEmpty) {
        return Ipv6ConnectivityResult(
          success: false,
          latency: timings.dns,
          stageFailed: ProbeStage.dns,
          failure: DNSFailure('No IPv6 address found for "$host"'),
          timings: timings,
        );
      }

      address = ipv6.first;
    } on TimeoutException {
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      return Ipv6ConnectivityResult(
        success: false,
        latency: timings.dns,
        stageFailed: ProbeStage.dns,
        failure: const TimeoutFailure('IPv6 DNS lookup timed out'),
        timings: timings,
      );
    } on SocketException catch (error) {
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      return Ipv6ConnectivityResult(
        success: false,
        latency: timings.dns,
        stageFailed: ProbeStage.dns,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.dns,
        ),
        timings: timings,
      );
    } catch (error) {
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      return Ipv6ConnectivityResult(
        success: false,
        latency: timings.dns,
        stageFailed: ProbeStage.dns,
        failure: ProbeFailureMapper.unknown(error),
        timings: timings,
      );
    }

    final tcpWatch = Stopwatch()..start();
    Socket? socket;

    try {
      socket = await Socket.connect(
        address,
        port,
        timeout: timeout,
      );
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);

      return Ipv6ConnectivityResult(
        success: true,
        latency: timings.tcp,
        resolvedAddress: address.address,
        stageReached: ProbeStage.tcp,
        timings: timings,
      );
    } on TimeoutException {
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
      return Ipv6ConnectivityResult(
        success: false,
        latency: timings.tcp,
        resolvedAddress: address.address,
        stageReached: ProbeStage.dns,
        stageFailed: ProbeStage.tcp,
        failure: const TimeoutFailure('IPv6 connect timed out'),
        timings: timings,
      );
    } on SocketException catch (error) {
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
      return Ipv6ConnectivityResult(
        success: false,
        latency: timings.tcp,
        resolvedAddress: address.address,
        stageReached: ProbeStage.dns,
        stageFailed: ProbeStage.tcp,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.tcp,
        ),
        timings: timings,
      );
    } catch (error) {
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
      return Ipv6ConnectivityResult(
        success: false,
        latency: timings.tcp,
        resolvedAddress: address.address,
        stageReached: ProbeStage.dns,
        stageFailed: ProbeStage.tcp,
        failure: ProbeFailureMapper.unknown(error),
        timings: timings,
      );
    } finally {
      await socket?.close();
    }
  }
}
