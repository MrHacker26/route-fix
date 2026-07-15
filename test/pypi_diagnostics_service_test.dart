import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/pypi/dart_io_pypi_diagnostics_service.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/services/http_probe_service.dart';

void main() {
  test('probes pypi.org and files.pythonhosted.org', () async {
    final fake = _FakeProbe();
    final service = DartIoPypiDiagnosticsService(probe: fake);

    final result = await service.check();

    expect(
      fake.uris,
      [
        DartIoPypiDiagnosticsService.defaultIndexEndpoint,
        DartIoPypiDiagnosticsService.defaultFilesEndpoint,
      ],
    );

    expect(result.index.hostname, 'pypi.org');
    expect(result.index.success, isTrue);
    expect(result.index.httpStatus, 200);
    expect(result.index.latency, const Duration(milliseconds: 11));
    expect(result.index.error, isNull);

    expect(result.files.hostname, 'files.pythonhosted.org');
    expect(result.files.success, isTrue);
    expect(result.files.httpStatus, 200);
    expect(result.success, isTrue);
  });

  test('overall success is false when one host fails', () async {
    final fake = _FakeProbe(failHost: 'files.pythonhosted.org');
    final service = DartIoPypiDiagnosticsService(probe: fake);

    final result = await service.check();

    expect(result.index.success, isTrue);
    expect(result.files.success, isFalse);
    expect(result.files.error, isNotNull);
    expect(result.success, isFalse);
  });
}

class _FakeProbe implements HttpProbeService {
  _FakeProbe({this.failHost});

  final String? failHost;
  final List<Uri> uris = [];

  @override
  Future<HttpProbeResult> probe(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    uris.add(uri);
    if (uri.host == failHost) {
      return const HttpProbeResult(
        success: false,
        latency: Duration(milliseconds: 40),
        httpStatus: 503,
        failure: HTTPFailure('Unexpected HTTP status 503', statusCode: 503),
      );
    }
    return const HttpProbeResult(
      success: true,
      latency: Duration(milliseconds: 11),
      httpStatus: 200,
    );
  }
}
