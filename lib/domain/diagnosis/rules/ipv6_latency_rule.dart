import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../engine/diagnosis_evidence.dart';
import '../engine/diagnosis_observations.dart';
import 'diagnosis_rule.dart';
import 'diagnosis_rule_result.dart';

/// Fails when Prefer IPv4 / Disable IPv6 is backed by dual-stack evidence.
///
/// Requires DNS success, IPv4 success, and IPv6 that fails typed or is
/// significantly slower — never a generic failure alone.
final class Ipv6LatencyRule implements DiagnosisRule<DualStackObservation> {
  const Ipv6LatencyRule({
    this.threshold = const Duration(milliseconds: 200),
  });

  /// Legacy absolute threshold retained for callers; Prefer IPv4 also uses
  /// [DiagnosisEvidence.ipv6AbsoluteSlowFloor] and the dual-stack ratio.
  final Duration threshold;

  @override
  String get id => 'ipv6_latency';

  @override
  String get name => 'IPv6 latency';

  @override
  DiagnosisRuleResult evaluate(DualStackObservation input) {
    final canPrefer = DiagnosisEvidence.canRecommendPreferIpv4(
      dnsLookup: input.dnsLookup,
      ipv4: input.ipv4,
      ipv6: input.ipv6,
    );

    if (!canPrefer) {
      // Insufficient dual-stack contrast — do not create Prefer IPv4 issue.
      if (input.ipv6.success &&
          input.ipv6.latency != null &&
          input.ipv6.latency! > threshold &&
          !DiagnosisEvidence.dnsSucceeded(input.dnsLookup)) {
        return DiagnosisRuleResult.passed(confidence: 0.35);
      }
      return DiagnosisRuleResult.passed(confidence: 0.7);
    }

    const confidence = 0.92;
    final ipv6 = input.ipv6;
    final ipv4 = input.ipv4;

    if (!ipv6.success) {
      return DiagnosisRuleResult.failed(
        confidence: confidence,
        recommendation: Recommendation(
          id: 'prefer-ipv4-ipv6-failed',
          title: 'Prefer IPv4',
          detail: 'IPv4 is fine. IPv6 isn’t. Prefer IPv4 for now.',
          priority: DiagnosticSeverity.medium,
          actionLabel: 'Prefer IPv4',
          metadata: {
            'fix_kind': 'disable_ipv6',
            'evidence': 'ipv6_failed_ipv4_ok_dns_ok',
            if (ipv6.error != null && ipv6.error!.trim().isNotEmpty)
              'ipv6_error': ipv6.error!,
          },
        ),
      );
    }

    final ipv4Ms = ipv4.latency!.inMilliseconds;
    final ipv6Ms = ipv6.latency!.inMilliseconds;
    final ratio = ipv4Ms <= 0 ? 0.0 : ipv6Ms / ipv4Ms;

    return DiagnosisRuleResult.failed(
      confidence: confidence,
      recommendation: Recommendation(
        id: 'ipv6-latency-high',
        title: 'Prefer IPv4',
        detail: ratio >= 2
            ? 'IPv6 is about ${ratio.round()}× slower than IPv4. Prefer IPv4 for now.'
            : 'IPv6 is slower than IPv4 right now. Prefer IPv4 for now.',
        priority: DiagnosticSeverity.medium,
        actionLabel: 'Prefer IPv4',
        metadata: {
          'fix_kind': 'disable_ipv6',
          'evidence': 'ipv6_significantly_slower',
          'ipv4_tcp_ms': '$ipv4Ms',
          'ipv6_tcp_ms': '$ipv6Ms',
          'ipv4_latency_ms': '$ipv4Ms',
          'ipv6_latency_ms': '$ipv6Ms',
        },
      ),
    );
  }
}
