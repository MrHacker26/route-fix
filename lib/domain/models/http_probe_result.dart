import '../../core/errors/app_failure.dart';

/// Outcome of an HTTP reachability probe.
class HttpProbeResult {
  const HttpProbeResult({
    required this.success,
    this.latency,
    this.httpStatus,
    this.failure,
  });

  final bool success;
  final Duration? latency;
  final int? httpStatus;

  /// Structured failure when [success] is false.
  final AppFailure? failure;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}
