import '../models/http_probe_result.dart';

/// Measures reachability / latency to GitHub over HTTP(S).
///
/// Connectivity probe only — no diagnosis or scoring.
abstract interface class GithubDiagnosticsService {
  Future<HttpProbeResult> check();
}
