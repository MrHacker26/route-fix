import '../models/http_probe_result.dart';

/// Measures reachability / latency to Cloudflare over HTTP(S).
///
/// Connectivity probe only — no diagnosis or scoring.
abstract interface class CloudflareDiagnosticsService {
  Future<HttpProbeResult> check();
}
