import 'dart:async';
import 'dart:io';

import '../../../domain/models/ipv6_connectivity_result.dart';
import '../../../domain/services/ipv6_connectivity_service.dart';

/// IPv6 reachability via DNS lookup + TCP connect (`dart:io`).
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
        error: 'Hostname must not be empty',
      );
    }

    if (port < 1 || port > 65535) {
      return const Ipv6ConnectivityResult(
        success: false,
        error: 'Port must be between 1 and 65535',
      );
    }

    late final InternetAddress address;
    try {
      final addresses = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv6,
      ).timeout(timeout);

      final ipv6 = addresses
          .where((item) => item.type == InternetAddressType.IPv6)
          .toList(growable: false);

      if (ipv6.isEmpty) {
        return Ipv6ConnectivityResult(
          success: false,
          error: 'No IPv6 address found for "$host"',
        );
      }

      address = ipv6.first;
    } on TimeoutException {
      return const Ipv6ConnectivityResult(
        success: false,
        error: 'IPv6 DNS lookup timed out',
      );
    } on SocketException catch (error) {
      return Ipv6ConnectivityResult(
        success: false,
        error: error.message.isEmpty ? 'IPv6 DNS lookup failed' : error.message,
      );
    } catch (error) {
      return Ipv6ConnectivityResult(
        success: false,
        error: error.toString(),
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

      return Ipv6ConnectivityResult(
        success: true,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
      );
    } on TimeoutException {
      stopwatch.stop();
      return Ipv6ConnectivityResult(
        success: false,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
        error: 'IPv6 connect timed out',
      );
    } on SocketException catch (error) {
      stopwatch.stop();
      return Ipv6ConnectivityResult(
        success: false,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
        error: error.message.isEmpty ? 'IPv6 connect failed' : error.message,
      );
    } catch (error) {
      stopwatch.stop();
      return Ipv6ConnectivityResult(
        success: false,
        latency: stopwatch.elapsed,
        resolvedAddress: address.address,
        error: error.toString(),
      );
    } finally {
      await socket?.close();
    }
  }
}
