import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/http_probe_result.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when a GitHub HTTP probe did not succeed.
final class GitHubConnectivityRule
    implements DiagnosisRule<HttpProbeResult> {
  const GitHubConnectivityRule();

  @override
  String get id => 'github_connectivity';

  @override
  String get name => 'GitHub connectivity';

  @override
  DiagnosisRuleResult evaluate(HttpProbeResult input) {
    if (input.success) {
      return DiagnosisRuleResult.passed(confidence: 0.9);
    }

    final status = input.httpStatus;
    return DiagnosisRuleResult.failed(
      confidence: 0.92,
      recommendation: Recommendation(
        id: 'github-unreachable',
        title: 'GitHub is hard to reach',
        detail: input.error ??
            (status != null
                ? 'GitHub answered with an unexpected status ($status).'
                : 'We couldn’t complete a check against GitHub just now.'),
        priority: DiagnosticSeverity.high,
      ),
    );
  }
}
