import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/ipv6/dart_io_ipv6_connectivity_service.dart';
import 'package:route_fix/domain/models/probe_stage.dart';

void main() {
  const service = DartIoIpv6ConnectivityService();

  test('rejects empty hostname', () async {
    final result = await service.check('  ');

    expect(result.success, isFalse);
    expect(result.error, 'Hostname must not be empty');
    expect(result.resolvedAddress, isNull);
    expect(result.latency, isNull);
  });

  test('isNativeIpv6Address rejects IPv4-mapped addresses', () {
    expect(
      isNativeIpv6Address(InternetAddress('::ffff:127.0.0.1')),
      isFalse,
    );
    expect(
      isNativeIpv6Address(InternetAddress('::ffff:8.8.8.8')),
      isFalse,
    );
    expect(isNativeIpv6Address(InternetAddress('::1')), isTrue);
    expect(
      isNativeIpv6Address(InternetAddress('2001:db8::1')),
      isTrue,
    );
    expect(
      isNativeIpv6Address(InternetAddress.loopbackIPv4),
      isFalse,
    );
  });

  test('connects to local IPv6 listener through DNS then TCP', () async {
    late final ServerSocket server;
    try {
      server = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
    } on SocketException catch (_) {
      // Some CI / desktop hosts have IPv6 loopback disabled.
      return;
    }
    addTearDown(server.close);

    final result = await service.check(
      'localhost',
      port: server.port,
    );

    // localhost may resolve to ::1 (native) and/or ::ffff:127.0.0.1 (mapped).
    // Success is only valid with a native IPv6 address.
    if (result.success) {
      expect(result.error, isNull);
      expect(result.resolvedAddress, isNotNull);
      expect(result.resolvedAddress!.toLowerCase().startsWith('::ffff:'), isFalse);
      expect(result.stageReached, ProbeStage.tcp);
      expect(result.timings.tcp, isNotNull);
      expect(result.latency, result.timings.tcp);
    } else {
      expect(result.failure, isA<DNSFailure>());
      expect(
        result.error,
        DartIoIpv6ConnectivityService.noIpv6Advertised,
      );
      expect(result.stageFailed, ProbeStage.dns);
    }
  });
}
