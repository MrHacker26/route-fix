import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/github/dart_io_github_diagnostics_service.dart';
import 'package:route_fix/data/services/http/dart_io_http_probe_service.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/services/http_probe_service.dart';

void main() {
  group('DartIoHttpProbeService', () {
    const probe = DartIoHttpProbeService();

    test('rejects non-http URI', () async {
      final result = await probe.probe(Uri.parse('ftp://example.com'));

      expect(result.success, isFalse);
      expect(result.error, 'URI must use http or https');
      expect(result.failure, isA<UnknownFailure>());
    });

    test('probes local HTTP server', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      });

      final result = await probe.probe(
        Uri.parse('http://127.0.0.1:${server.port}/'),
      );

      expect(result.success, isTrue);
      expect(result.httpStatus, HttpStatus.ok);
      expect(result.latency, isNotNull);
      expect(result.error, isNull);
    });
  });

  group('DartIoGithubDiagnosticsService', () {
    test('delegates to injected probe with GitHub endpoint', () async {
      final fake = _FakeProbe();
      final service = DartIoGithubDiagnosticsService(probe: fake);

      final result = await service.check();

      expect(fake.lastUri, DartIoGithubDiagnosticsService.defaultEndpoint);
      expect(result.success, isTrue);
      expect(result.httpStatus, 200);
      expect(result.latency, const Duration(milliseconds: 12));
    });
  });
}

class _FakeProbe implements HttpProbeService {
  Uri? lastUri;

  @override
  Future<HttpProbeResult> probe(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    lastUri = uri;
    return const HttpProbeResult(
      success: true,
      latency: Duration(milliseconds: 12),
      httpStatus: 200,
    );
  }
}
