import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/pypi_diagnostics_result.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when any successful PyPI host probe exceeds [threshold] latency.
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
      if (target.latency! <= threshold) continue;
      if (slowest == null || target.latency! > slowest.latency!) {
        slowest = target;
      }
    }

    if (slowest == null) {
      return DiagnosisRuleResult.passed(confidence: 0.8);
    }

    return DiagnosisRuleResult.failed(
      confidence: 0.88,
      recommendation: Recommendation(
        id: 'pypi-latency-high',
        title: 'PyPI path is slow',
        detail:
            '${slowest.hostname} responded in '
            '${slowest.latency!.inMilliseconds} ms '
            '(threshold ${threshold.inMilliseconds} ms).',
        priority: DiagnosticSeverity.medium,
      ),
    );
  }
}
