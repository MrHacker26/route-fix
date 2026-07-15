import 'diagnostic_check_result.dart';
import 'health_score.dart';
import 'issue.dart';
import 'latency_sample.dart';
import 'recommendation.dart';

/// Lifecycle of a full diagnostic run.
enum ScanPhase {
  idle,
  preparing,
  running,
  completing,
  completed,
  cancelled,
  failed,
}

/// Aggregate session produced by a diagnostics run.
class ScanSession {
  const ScanSession({
    required this.id,
    required this.startedAt,
    required this.phase,
    required this.checks,
    required this.score,
    required this.issues,
    required this.recommendations,
    required this.latencySamples,
    this.completedAt,
    this.duration,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Duration? duration;
  final ScanPhase phase;
  final List<DiagnosticCheckResult> checks;
  final HealthScore score;
  final List<Issue> issues;
  final List<Recommendation> recommendations;
  final List<LatencySample> latencySamples;
}
