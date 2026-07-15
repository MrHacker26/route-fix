import '../../core/errors/app_failure.dart';
import 'probe_stage.dart';
import 'probe_timings.dart';

/// Outcome of an HTTP reachability probe with per-stage diagnostics.
class HttpProbeResult {
  const HttpProbeResult({
    required this.success,
    this.latency,
    this.httpStatus,
    this.failure,
    this.stageReached,
    this.stageFailed,
    this.timings = ProbeTimings.empty,
  });

  final bool success;

  /// Elapsed time for the terminal stage (last success, or the failing stage).
  /// Prefer [timings] for stage-accurate breakdowns.
  final Duration? latency;

  final int? httpStatus;

  /// Structured failure when [success] is false.
  final AppFailure? failure;

  /// Last stage that completed successfully (null if none).
  final ProbeStage? stageReached;

  /// Stage where the probe stopped with a failure (null on full success).
  final ProbeStage? stageFailed;

  /// Per-stage wall times (DNS / TCP / TLS / HTTP).
  final ProbeTimings timings;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}
