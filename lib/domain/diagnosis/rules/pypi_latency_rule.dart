import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/pypi_diagnostics_result.dart';
import '../engine/diagnosis_evidence.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when any successful PyPI host probe exceeds [threshold] latency.
///
/// Recommendations require measured success latency — never generic failures
/// on the slow host.
final class PyPILatencyRule
    implements DiagnosisRule<PypiDiagnosticsResult> {
  const PyPILatencyRule({
    this.threshold = const Duration(milliseconds: 400),
  });

  final Duration threshold;

  @override
  String get id => 'pypi_latency';

  @override
  String get name => 'PyPI latency';

  @override
  DiagnosisRuleResult evaluate(PypiDiagnosticsResult input) {
    HostHttpProbeResult? slowest;

    for (final target in input.targets) {
      if (!target.success || target.latency == null) continue;
      if (DiagnosisEvidence.isGenericFailure(target.failure)) continue;
      if (target.latency! <= threshold) continue;
      if (slowest == null || target.latency! > slowest.latency!) {
        slowest = target;
      }
    }

    if (slowest == null) {
      return DiagnosisRuleResult.passed(confidence: 0.8);
    }

    const confidence = 0.88;
    return DiagnosisRuleResult.failed(
      confidence: confidence,
      recommendation: DiagnosisEvidence.isHighConfidence(confidence)
          ? Recommendation(
              id: 'pypi-latency-high',
              title: 'Python packages may download slowly',
              detail:
                  '${slowest.hostname} took about '
                  '${slowest.latency!.inMilliseconds} ms to respond. '
                  'Installs and updates can feel slower than usual.',
              priority: DiagnosticSeverity.medium,
            )
          : null,
    );
  }
}
