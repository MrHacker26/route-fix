import '../../core/errors/app_failure.dart';
import 'probe_stage.dart';
import 'probe_timings.dart';

/// Outcome of an IPv4 connectivity check against a hostname.
class Ipv4ConnectivityResult {
  const Ipv4ConnectivityResult({
    required this.success,
    this.latency,
    this.resolvedAddress,
    this.failure,
    this.stageReached,
    this.stageFailed,
    this.timings = ProbeTimings.empty,
  });

  final bool success;

  /// Elapsed time for the terminal stage (TCP connect on success).
  /// Prefer [timings] for DNS vs TCP breakdowns.
  final Duration? latency;

  final String? resolvedAddress;

  /// Structured failure when [success] is false.
  final AppFailure? failure;

  /// Last stage that completed successfully (null if none).
  final ProbeStage? stageReached;

  /// Stage where the probe stopped with a failure (null on full success).
  final ProbeStage? stageFailed;

  /// Per-stage wall times (DNS / TCP).
  final ProbeTimings timings;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}
