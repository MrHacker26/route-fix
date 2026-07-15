import '../../../core/errors/app_failure.dart';
import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/http_probe_result.dart';
import '../../models/probe_stage.dart';
import '../engine/diagnosis_evidence.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when a GitHub HTTP probe did not succeed.
///
/// Recommendations require a typed TLS/HTTP-stage failure — never a generic
/// failure, and never a bare DNS miss that should be owned by DNS rules.
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

    if (DiagnosisEvidence.isGenericFailure(input.failure)) {
      return DiagnosisRuleResult.failed(
        confidence: 0.4,
        // No recommendation from a generic failure.
      );
    }

    final canRecommend = _hasGithubSpecificEvidence(input);
    final confidence = canRecommend ? 0.92 : 0.55;
    final status = input.httpStatus;

    return DiagnosisRuleResult.failed(
      confidence: confidence,
      recommendation: canRecommend &&
              DiagnosisEvidence.isHighConfidence(confidence)
          ? Recommendation(
              id: 'github-unreachable',
              title: 'GitHub is hard to reach',
              detail: input.error ??
                  (status != null
                      ? 'GitHub replied with status $status.'
                      : 'Couldn’t finish the GitHub check.'),
              priority: DiagnosticSeverity.high,
            )
          : null,
    );
  }

  bool _hasGithubSpecificEvidence(HttpProbeResult input) {
    final failure = input.failure;
    if (failure == null) return false;
    if (DiagnosisEvidence.isGenericFailure(failure)) return false;

    // DNS-stage collapse belongs to DNS diagnosis, not a GitHub fix.
    if (input.stageFailed == ProbeStage.dns || failure is DNSFailure) {
      return false;
    }

    if (failure is HTTPFailure) return true;
    if (failure is TLSFailure) return true;
    if (failure is TCPFailure && input.stageFailed == ProbeStage.tcp) {
      return true;
    }
    if (failure is TimeoutFailure &&
        (input.stageFailed == ProbeStage.tls ||
            input.stageFailed == ProbeStage.http ||
            input.stageFailed == ProbeStage.tcp)) {
      return true;
    }
    return false;
  }
}
