import 'diagnosis_rule_result.dart';

/// A single-condition diagnosis rule.
///
/// No orchestration — callers invoke [evaluate] on one observation at a time.
abstract interface class DiagnosisRule<TInput> {
  String get id;

  String get name;

  DiagnosisRuleResult evaluate(TInput input);
}
