import '../../../core/abstractions/result.dart';
import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/dns_lookup_result.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when a DNS lookup observation did not succeed.
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
          return DiagnosisRuleResult.failed(
            confidence: 0.9,
            recommendation: Recommendation(
              id: 'dns-empty',
              title: 'DNS returned no addresses',
              detail: 'Lookup for "${value.hostname}" produced no A/AAAA records.',
              priority: DiagnosticSeverity.high,
            ),
          );
        }
        return DiagnosisRuleResult.passed(confidence: 0.9);
      case Failure(:final error):
        return DiagnosisRuleResult.failed(
          confidence: 0.95,
          recommendation: Recommendation(
            id: 'dns-failed',
            title: 'DNS lookup failed',
            detail: error.toString(),
            priority: DiagnosticSeverity.high,
          ),
        );
    }
  }
}
