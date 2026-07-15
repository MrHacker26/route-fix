import 'dart:async';
import 'dart:io';

import '../../../domain/models/http_probe_result.dart';
import '../../../domain/services/http_probe_service.dart';

/// Generic HTTP(S) probe via `dart:io` [HttpClient].
class DartIoHttpProbeService implements HttpProbeService {
  const DartIoHttpProbeService();

  @override
  Future<HttpProbeResult> probe(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!(uri.isScheme('http') || uri.isScheme('https'))) {
      return const HttpProbeResult(
        success: false,
        error: 'URI must use http or https',
      );
    }

    final client = HttpClient()..connectionTimeout = timeout;
    final stopwatch = Stopwatch()..start();

    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set(HttpHeaders.userAgentHeader, 'RouteFix/1.0');

      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      // Drain body so the connection can close cleanly.
      await response.drain<void>();

      final status = response.statusCode;
      final ok = status >= 200 && status < 400;

      return HttpProbeResult(
        success: ok,
        latency: stopwatch.elapsed,
        httpStatus: status,
        error: ok ? null : 'Unexpected HTTP status $status',
      );
    } on TimeoutException {
      stopwatch.stop();
      return HttpProbeResult(
        success: false,
        latency: stopwatch.elapsed,
        error: 'HTTP probe timed out',
      );
    } on SocketException catch (error) {
      stopwatch.stop();
      return HttpProbeResult(
        success: false,
        latency: stopwatch.elapsed,
        error: error.message.isEmpty ? 'HTTP probe failed' : error.message,
      );
    } on HttpException catch (error) {
      stopwatch.stop();
      return HttpProbeResult(
        success: false,
        latency: stopwatch.elapsed,
        error: error.message,
      );
    } on HandshakeException catch (error) {
      stopwatch.stop();
      return HttpProbeResult(
        success: false,
        latency: stopwatch.elapsed,
        error: error.message,
      );
    } catch (error) {
      stopwatch.stop();
      return HttpProbeResult(
        success: false,
        latency: stopwatch.elapsed,
        error: error.toString(),
      );
    } finally {
      client.close(force: true);
    }
  }
}
