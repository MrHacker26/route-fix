import '../../../domain/models/http_probe_result.dart';
import '../../../domain/services/cloudflare_diagnostics_service.dart';
import '../../../domain/services/http_probe_service.dart';
import '../http/dart_io_http_probe_service.dart';

/// Cloudflare HTTP latency probe built on the generic [HttpProbeService].
class DartIoCloudflareDiagnosticsService
    implements CloudflareDiagnosticsService {
  DartIoCloudflareDiagnosticsService({
    HttpProbeService? probe,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 8),
  })  : _probe = probe ?? const DartIoHttpProbeService(),
        _endpoint = endpoint ?? defaultEndpoint;

  static final Uri defaultEndpoint = Uri.parse('https://www.cloudflare.com/');

  final HttpProbeService _probe;
  final Uri _endpoint;
  final Duration timeout;

  @override
  Future<HttpProbeResult> check() {
    return _probe.probe(_endpoint, timeout: timeout);
  }
}
