import '../../../core/abstractions/result.dart';
import '../../../core/errors/app_failure.dart';
import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/dns_lookup_result.dart';
import '../engine/diagnosis_evidence.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when a DNS lookup observation did not succeed.
///
/// Recommendations require a typed [DNSFailure] or DNS [TimeoutFailure] —
/// never [UnknownFailure] / [CancellationFailure].
final class DnsFailureRule
    implements DiagnosisRule<Result<DnsLookupResult>> {
  const DnsFailureRule();

  @override
  String get id => 'dns_failure';

  @override
  String get name => 'DNS failure';

  @override
  DiagnosisRuleResult evaluate(Result<DnsLookupResult> input) {
    switch (input) {
      case Success(:final value):
        if (value.ipv4Addresses.isEmpty && value.ipv6Addresses.isEmpty) {
          const confidence = 0.9;
          return DiagnosisRuleResult.failed(
            confidence: confidence,
            recommendation: DiagnosisEvidence.isHighConfidence(confidence)
                ? Recommendation(
                    id: 'dns-empty',
                    title: 'Name lookup came up empty',
                    detail:
                        'No addresses found for "${value.hostname}". '
                        'Apps that need that name may stall.',
                    priority: DiagnosticSeverity.high,
                  )
                : null,
          );
        }
        return DiagnosisRuleResult.passed(confidence: 0.9);
      case Failure(:final error):
        final failure = error is AppFailure ? error : UnknownFailure('$error');

        if (DiagnosisEvidence.isGenericFailure(failure)) {
          return DiagnosisRuleResult.failed(
            confidence: 0.4,
            // No recommendation from a generic failure.
          );
        }

        final typed = failure is DNSFailure || failure is TimeoutFailure;
        final confidence = typed ? 0.95 : 0.6;

        return DiagnosisRuleResult.failed(
          confidence: confidence,
          recommendation: typed && DiagnosisEvidence.isHighConfidence(confidence)
              ? Recommendation(
                  id: 'dns-failed',
                  title: 'Name lookup failed',
                  detail: failure.message,
                  priority: DiagnosticSeverity.high,
                )
              : null,
        );
    }
  }
}
