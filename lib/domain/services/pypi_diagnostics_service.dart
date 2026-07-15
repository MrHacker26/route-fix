import '../models/pypi_diagnostics_result.dart';

/// Measures reachability / latency to PyPI hosts over HTTP(S).
///
/// Connectivity probe only — no diagnosis or scoring.
abstract interface class PypiDiagnosticsService {
  Future<PypiDiagnosticsResult> check();
}
