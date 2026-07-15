import '../models/http_probe_result.dart';

/// Generic HTTP probe — measures latency and captures status.
///
/// No diagnosis or scoring.
abstract interface class HttpProbeService {
  Future<HttpProbeResult> probe(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  });
}
