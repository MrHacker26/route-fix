import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/http/dart_io_http_probe_service.dart';
import 'package:route_fix/domain/models/probe_stage.dart';

void main() {
  const service = DartIoHttpProbeService();

  test('stages through DNS → TCP → HTTP on local server', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((client) async {
      // Consume request then respond.
      await client.first.timeout(const Duration(seconds: 2));
      client.write(
        'HTTP/1.1 200 OK\r\n'
        'Content-Length: 0\r\n'
        'Connection: close\r\n'
        '\r\n',
      );
      await client.close();
    });

    final result = await service.probe(
      Uri.parse('http://127.0.0.1:${server.port}/'),
    );

    expect(result.success, isTrue);
    expect(result.httpStatus, 200);
    expect(result.stageReached, ProbeStage.http);
    expect(result.stageFailed, isNull);
    expect(result.failure, isNull);
    expect(result.latency, isNotNull);
    expect(result.latency! >= Duration.zero, isTrue);
  });

  test('reports TCP stage failure for closed port', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();

    final result = await service.probe(
      Uri.parse('http://127.0.0.1:$port/'),
      timeout: const Duration(seconds: 2),
    );

    expect(result.success, isFalse);
    expect(result.stageReached, ProbeStage.dns);
    expect(result.stageFailed, ProbeStage.tcp);
    expect(result.failure, isA<TCPFailure>());
    expect(result.latency, isNotNull);
  });

  test('reports DNS stage failure for unresolvable host', () async {
    final result = await service.probe(
      Uri.parse('http://no-such-host.invalid./'),
      timeout: const Duration(seconds: 5),
    );

    expect(result.success, isFalse);
    expect(result.stageReached, isNull);
    expect(result.stageFailed, ProbeStage.dns);
    expect(
      result.failure,
      anyOf(isA<DNSFailure>(), isA<TimeoutFailure>()),
    );
    expect(result.latency, isNotNull);
  });

  test('reports HTTP stage failure for unexpected status', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((client) async {
      await client.first.timeout(const Duration(seconds: 2));
      client.write(
        'HTTP/1.1 503 Service Unavailable\r\n'
        'Content-Length: 0\r\n'
        'Connection: close\r\n'
        '\r\n',
      );
      await client.close();
    });

    final result = await service.probe(
      Uri.parse('http://127.0.0.1:${server.port}/'),
    );

    expect(result.success, isFalse);
    expect(result.httpStatus, 503);
    expect(result.stageReached, ProbeStage.http);
    expect(result.stageFailed, ProbeStage.http);
    expect(result.failure, isA<HTTPFailure>());
  });
}
