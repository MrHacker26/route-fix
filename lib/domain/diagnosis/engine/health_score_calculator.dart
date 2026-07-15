import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/network_health.dart';
import '../rules/diagnosis_rule_result.dart';

/// Derives overall [NetworkHealth] from rule outcomes.
final class HealthScoreCalculator {
  const HealthScoreCalculator();

  NetworkHealth calculate({
    required List<DiagnosisRuleResult> results,
    required int failedCount,
    DateTime? checkedAt,
  }) {
    var score = 100.0;

    for (final result in results) {
      if (!result.failed) continue;
      final severity = result.recommendation?.priority ?? DiagnosticSeverity.medium;
      score -= _penaltyFor(severity) * result.confidence;
    }

    final clamped = score.round().clamp(0, 100);
    return NetworkHealth(
      score: clamped,
      label: _labelFor(clamped),
      summary: failedCount == 0
          ? 'All diagnosis rules passed.'
          : '$failedCount issue${failedCount == 1 ? '' : 's'} detected.',
      checkedAt: checkedAt,
      metrics: {
        'rules_evaluated': results.length.toDouble(),
        'rules_failed': failedCount.toDouble(),
      },
    );
  }

  double _penaltyFor(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.info => 4,
      DiagnosticSeverity.low => 8,
      DiagnosticSeverity.medium => 14,
      DiagnosticSeverity.high => 22,
      DiagnosticSeverity.critical => 35,
    };
  }

  String _labelFor(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 55) return 'Fair';
    if (score >= 35) return 'Poor';
    return 'Critical';
  }
}
