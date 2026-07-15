import 'diagnostic_target.dart';
import 'health_score.dart';

/// Outcome of a single diagnostic check against a target.
class DiagnosticCheckResult {
  const DiagnosticCheckResult({
    required this.targetId,
    required this.status,
    required this.tone,
    required this.summary,
    this.latency,
    this.checkedAt,
  });

  final String targetId;
  final CheckStatus status;
  final HealthTone tone;
  final String summary;
  final Duration? latency;
  final DateTime? checkedAt;
}

enum CheckStatus {
  pending,
  running,
  succeeded,
  warning,
  failed,
  skipped,
}

/// Convenience pairing of target + latest result.
class TargetedCheck {
  const TargetedCheck({
    required this.target,
    required this.result,
  });

  final DiagnosticTarget target;
  final DiagnosticCheckResult result;
}
