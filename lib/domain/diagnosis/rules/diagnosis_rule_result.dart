import '../../models/diagnostics/recommendation.dart';

/// Outcome of evaluating a single diagnosis rule.
///
/// Exactly one of [passed] / [failed] is true.
final class DiagnosisRuleResult {
  const DiagnosisRuleResult._({
    required this.passed,
    required this.failed,
    required this.confidence,
    this.recommendation,
  });

  /// Condition held — no issue detected for this rule.
  factory DiagnosisRuleResult.passed({
    required double confidence,
    Recommendation? recommendation,
  }) {
    return DiagnosisRuleResult._(
      passed: true,
      failed: false,
      confidence: _clampConfidence(confidence),
      recommendation: recommendation,
    );
  }

  /// Condition violated — issue detected for this rule.
  factory DiagnosisRuleResult.failed({
    required double confidence,
    Recommendation? recommendation,
  }) {
    return DiagnosisRuleResult._(
      passed: false,
      failed: true,
      confidence: _clampConfidence(confidence),
      recommendation: recommendation,
    );
  }

  final bool passed;
  final bool failed;

  /// Confidence in the outcome, inclusive range 0.0–1.0.
  final double confidence;

  /// Optional next step when the rule fails (or advisory when it passes).
  final Recommendation? recommendation;

  static double _clampConfidence(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
