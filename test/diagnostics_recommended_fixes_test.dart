import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/macos_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostic_issue.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostic_report.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostic_severity.dart';
import 'package:route_fix/domain/models/diagnostics/network_health.dart';
import 'package:route_fix/features/diagnostics/diagnostics_result_view_data.dart';

void main() {
  test('surfaces one primary fix and avoids contradictory IPv6 actions', () {
    final report = DiagnosticReport(
      id: 'r1',
      createdAt: DateTime.utc(2026, 7, 15),
      health: const NetworkHealth(score: 70, label: 'Fair'),
      confidence: 0.8,
      issues: const [
        DiagnosticIssue(
          id: 'ipv6_latency',
          title: 'IPv6 latency',
          description: 'High latency',
          severity: DiagnosticSeverity.medium,
          code: 'ipv6_latency',
          metadata: {'rule_confidence': '0.96'},
        ),
        DiagnosticIssue(
          id: 'ipv6_unavailable',
          title: 'IPv6 unavailable',
          description: 'Down',
          severity: DiagnosticSeverity.low,
          code: 'ipv6_unavailable',
        ),
      ],
      recommendations: const [],
      metadata: const {
        'ipv4_latency_ms': '20',
        'ipv6_latency_ms': '360',
      },
    );

    final selected = DiagnosticsResultViewData.selectRecommendedFixes(
      report: report,
      fixProvider: MacOsFixProvider(),
    );

    expect(selected.primary?.kind, FixActionKind.disableIpv6);
    expect(
      selected.secondary.map((f) => f.kind),
      isNot(contains(FixActionKind.enableIpv6)),
    );
    expect(selected.primary?.why, contains('slower than IPv4'));
    expect(selected.primary?.confidenceLabel, 'Strong');
    expect(selected.primary?.backedByRuleIds, contains('ipv6_latency'));
  });

  test('returns no recommended fixes when there are no matching issues', () {
    final report = DiagnosticReport(
      id: 'r2',
      createdAt: DateTime.utc(2026, 7, 15),
      health: const NetworkHealth(score: 95, label: 'Good'),
      confidence: 0.9,
      issues: const [],
      recommendations: const [],
    );

    final data = DiagnosticsResultViewData.fromReport(
      report,
      fixProvider: MacOsFixProvider(),
    );

    expect(data.primaryFix, isNull);
    expect(data.secondaryFixes, isEmpty);
  });
}
