import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/services/ipv4/dart_io_ipv4_connectivity_service.dart';

void main() {
  const service = DartIoIpv4ConnectivityService();

  test('rejects empty hostname', () async {
    final result = await service.check('  ');

    expect(result.success, isFalse);
    expect(result.error, 'Hostname must not be empty');
    expect(result.resolvedAddress, isNull);
    expect(result.latency, isNull);
  });

  test('connects to local IPv4 listener', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    final result = await service.check(
      'localhost',
      port: server.port,
    );

    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.resolvedAddress, anyOf('127.0.0.1', '::ffff:127.0.0.1'));
    expect(result.latency, isNotNull);
    expect(result.latency! >= Duration.zero, isTrue);
  });
}
