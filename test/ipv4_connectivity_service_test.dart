import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/ipv4/dart_io_ipv4_connectivity_service.dart';
import 'package:route_fix/domain/models/probe_stage.dart';

void main() {
  const service = DartIoIpv4ConnectivityService();

  test('rejects empty hostname', () async {
    final result = await service.check('  ');

    expect(result.success, isFalse);
    expect(result.error, 'Hostname must not be empty');
    expect(result.resolvedAddress, isNull);
    expect(result.latency, isNull);
  });

  test('connects to local IPv4 listener through DNS then TCP', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    final result = await service.check(
      'localhost',
      port: server.port,
    );

    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.resolvedAddress, anyOf('127.0.0.1', '::ffff:127.0.0.1'));
    expect(result.stageReached, ProbeStage.tcp);
    expect(result.stageFailed, isNull);
    expect(result.timings.dns, isNotNull);
    expect(result.timings.tcp, isNotNull);
    expect(result.latency, result.timings.tcp);
    expect(result.latency! >= Duration.zero, isTrue);
  });

  test('reports TCP stage failure for closed port', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();

    final result = await service.check('localhost', port: port);

    expect(result.success, isFalse);
    expect(result.stageReached, ProbeStage.dns);
    expect(result.stageFailed, ProbeStage.tcp);
    expect(result.failure, isA<TCPFailure>());
  });
}
