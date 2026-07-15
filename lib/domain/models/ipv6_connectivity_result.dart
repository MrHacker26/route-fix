import '../../core/errors/app_failure.dart';
import 'probe_stage.dart';

/// Outcome of an IPv6 connectivity check against a hostname.
class Ipv6ConnectivityResult {
  const Ipv6ConnectivityResult({
    required this.success,
    this.latency,
    this.resolvedAddress,
    this.failure,
    this.stageReached,
    this.stageFailed,
  });

  final bool success;

  /// Elapsed time for the terminal stage (TCP connect on success).
  final Duration? latency;

  final String? resolvedAddress;

  /// Structured failure when [success] is false.
  final AppFailure? failure;

  /// Last stage that completed successfully (null if none).
  final ProbeStage? stageReached;

  /// Stage where the probe stopped with a failure (null on full success).
  final ProbeStage? stageFailed;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}
