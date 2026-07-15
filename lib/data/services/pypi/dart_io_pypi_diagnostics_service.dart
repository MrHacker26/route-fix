import '../../../domain/models/http_probe_result.dart';
import '../../../domain/models/pypi_diagnostics_result.dart';
import '../../../domain/services/http_probe_service.dart';
import '../../../domain/services/pypi_diagnostics_service.dart';
import '../http/dart_io_http_probe_service.dart';

/// PyPI HTTP latency probes built on the generic [HttpProbeService].
class DartIoPypiDiagnosticsService implements PypiDiagnosticsService {
  DartIoPypiDiagnosticsService({
    HttpProbeService? probe,
    Uri? indexEndpoint,
    Uri? filesEndpoint,
    this.timeout = const Duration(seconds: 8),
  })  : _probe = probe ?? const DartIoHttpProbeService(),
        _indexEndpoint = indexEndpoint ?? defaultIndexEndpoint,
        _filesEndpoint = filesEndpoint ?? defaultFilesEndpoint;

  static final Uri defaultIndexEndpoint = Uri.parse('https://pypi.org/');
  static final Uri defaultFilesEndpoint =
      Uri.parse('https://files.pythonhosted.org/');

  final HttpProbeService _probe;
  final Uri _indexEndpoint;
  final Uri _filesEndpoint;
  final Duration timeout;

  @override
  Future<PypiDiagnosticsResult> check() async {
    final results = await Future.wait([
      _probeHost(_indexEndpoint),
      _probeHost(_filesEndpoint),
    ]);

    return PypiDiagnosticsResult(
      index: results[0],
      files: results[1],
    );
  }

  Future<HostHttpProbeResult> _probeHost(Uri endpoint) async {
    final HttpProbeResult probed = await _probe.probe(
      endpoint,
      timeout: timeout,
    );

    return HostHttpProbeResult(
      hostname: endpoint.host,
      success: probed.success,
      latency: probed.latency,
      httpStatus: probed.httpStatus,
      error: probed.error,
    );
  }
}
