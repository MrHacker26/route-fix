import '../engine/diagnosis_evidence.dart';
import '../engine/diagnosis_observations.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Observes IPv6 reachability.
///
/// Probe results alone never justify **Enable IPv6** (needs host-configuration
/// evidence). Prefer IPv4 / Disable IPv6 is owned by [Ipv6LatencyRule] when
/// dual-stack contrast is proven.
final class Ipv6UnavailableRule
    implements DiagnosisRule<DualStackObservation> {
  const Ipv6UnavailableRule();

  @override
  String get id => 'ipv6_unavailable';

  @override
  String get name => 'IPv6 unavailable';

  @override
  DiagnosisRuleResult evaluate(DualStackObservation input) {
    final ipv6 = input.ipv6;

    if (ipv6.success && ipv6.resolvedAddress != null) {
      return DiagnosisRuleResult.passed(confidence: 0.9);
    }

    // Prefer IPv4 ownership — do not also emit ipv6_unavailable (Enable).
    if (DiagnosisEvidence.canRecommendPreferIpv4(
      dnsLookup: input.dnsLookup,
      ipv4: input.ipv4,
      ipv6: ipv6,
    )) {
      return DiagnosisRuleResult.passed(confidence: 0.88);
    }

    // Insufficient evidence for Enable IPv6 — pass so Autofix does not attach
    // a contradictory Enable action to a generic or incomplete probe failure.
    return DiagnosisRuleResult.passed(confidence: 0.55);
  }
}
