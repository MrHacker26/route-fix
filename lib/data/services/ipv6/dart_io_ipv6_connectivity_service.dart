import 'dart:async';
import 'dart:io';

import '../../../core/errors/app_failure.dart';
import '../../../domain/models/ipv6_connectivity_result.dart';
import '../../../domain/models/probe_stage.dart';
import '../../../domain/models/probe_timings.dart';
import '../../../domain/services/ipv6_connectivity_service.dart';
import '../probe_failure_mapper.dart';

/// IPv6 reachability via native AAAA records then TCP (`dart:io`).
///
/// Never connects to IPv4-mapped IPv6 addresses (`::ffff:x.x.x.x`).
/// IPv4 and IPv6 paths stay independent.
class DartIoIpv6ConnectivityService implements Ipv6ConnectivityService {
  const DartIoIpv6ConnectivityService({
    this.timeout = const Duration(seconds: 8),
  });

  static const noIpv6Advertised = 'No IPv6 address advertised by target.';

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

      // Native AAAA only — never IPv4-mapped (::ffff:…) fabrications.
      final ipv6 = addresses.where(isNativeIpv6Address).toList(growable: false);

      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);

      if (ipv6.isEmpty) {
        return Ipv6ConnectivityResult(
          success: false,
          latency: timings.dns,
          stageFailed: ProbeStage.dns,
          failure: const DNSFailure(noIpv6Advertised),
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

/// True only for real IPv6 addresses — rejects IPv4-mapped `::ffff:a.b.c.d`.
bool isNativeIpv6Address(InternetAddress address) {
  if (address.type != InternetAddressType.IPv6) {
    return false;
  }

  final raw = address.rawAddress;
  if (raw.length != 16) {
    return false;
  }

  // IPv4-mapped IPv6 layout: 80 bits zero + 16 bits ones + 32-bit IPv4.
  var leadingZero = true;
  for (var i = 0; i < 10; i++) {
    if (raw[i] != 0) {
      leadingZero = false;
      break;
    }
  }
  if (leadingZero && raw[10] == 0xff && raw[11] == 0xff) {
    return false;
  }

  final textual = address.address.toLowerCase();
  if (textual.startsWith('::ffff:')) {
    return false;
  }

  return true;
}
