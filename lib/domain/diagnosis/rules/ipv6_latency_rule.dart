import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../../models/ipv6_connectivity_result.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when an IPv6 connection succeeds but latency exceeds [threshold].
final class Ipv6LatencyRule
    implements DiagnosisRule<Ipv6ConnectivityResult> {
  const Ipv6LatencyRule({
    this.threshold = const Duration(milliseconds: 200),
  });

  final Duration threshold;

  @override
  String get id => 'ipv6_latency';

  @override
  String get name => 'IPv6 latency';

  @override
  DiagnosisRuleResult evaluate(Ipv6ConnectivityResult input) {
    if (!input.success || input.latency == null) {
      return DiagnosisRuleResult.passed(confidence: 0.4);
    }

    if (input.latency! <= threshold) {
      return DiagnosisRuleResult.passed(confidence: 0.85);
    }

    return DiagnosisRuleResult.failed(
      confidence: 0.9,
      recommendation: Recommendation(
        id: 'ipv6-latency-high',
        title: 'IPv6 path is slow',
        detail:
            'IPv6 connected but latency (${input.latency!.inMilliseconds} ms) '
            'exceeded ${threshold.inMilliseconds} ms.',
        priority: DiagnosticSeverity.medium,
      ),
    );
  }
}
