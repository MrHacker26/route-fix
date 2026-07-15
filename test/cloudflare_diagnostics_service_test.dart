import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/services/cloudflare/dart_io_cloudflare_diagnostics_service.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/services/http_probe_service.dart';

void main() {
  test('delegates to injected probe with Cloudflare endpoint', () async {
    final fake = _FakeProbe();
    final service = DartIoCloudflareDiagnosticsService(probe: fake);

    final result = await service.check();

    expect(fake.lastUri, DartIoCloudflareDiagnosticsService.defaultEndpoint);
    expect(result.success, isTrue);
    expect(result.httpStatus, 200);
    expect(result.latency, const Duration(milliseconds: 9));
    expect(result.error, isNull);
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
      latency: Duration(milliseconds: 9),
      httpStatus: 200,
    );
  }
}
