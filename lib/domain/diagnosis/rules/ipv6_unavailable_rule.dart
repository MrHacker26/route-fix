import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/ipv6_connectivity_result.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when IPv6 connectivity did not succeed.
final class Ipv6UnavailableRule
    implements DiagnosisRule<Ipv6ConnectivityResult> {
  const Ipv6UnavailableRule();

  @override
  String get id => 'ipv6_unavailable';

  @override
  String get name => 'IPv6 unavailable';

  @override
  DiagnosisRuleResult evaluate(Ipv6ConnectivityResult input) {
    if (input.success && input.resolvedAddress != null) {
      return DiagnosisRuleResult.passed(confidence: 0.9);
    }

    return DiagnosisRuleResult.failed(
      confidence: 0.95,
      recommendation: Recommendation(
        id: 'ipv6-unavailable',
        title: 'IPv6 is unavailable',
        detail: input.error ??
            'No usable IPv6 route or address was observed for this host.',
        priority: DiagnosticSeverity.low,
      ),
    );
  }
}
