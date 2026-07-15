/// Outcome of an HTTP reachability probe.
class HttpProbeResult {
  const HttpProbeResult({
    required this.success,
    this.latency,
    this.httpStatus,
    this.error,
  });

  final bool success;
  final Duration? latency;
  final int? httpStatus;
  final String? error;
}
