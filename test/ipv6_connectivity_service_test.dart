import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/services/ipv6/dart_io_ipv6_connectivity_service.dart';

void main() {
  const service = DartIoIpv6ConnectivityService();

  test('rejects empty hostname', () async {
    final result = await service.check('  ');

    expect(result.success, isFalse);
    expect(result.error, 'Hostname must not be empty');
    expect(result.resolvedAddress, isNull);
    expect(result.latency, isNull);
  });

  test('connects to local IPv6 listener', () async {
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

    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.resolvedAddress, isNotNull);
    expect(result.resolvedAddress!.contains(':'), isTrue);
    expect(result.latency, isNotNull);
    expect(result.latency! >= Duration.zero, isTrue);
  });
}
