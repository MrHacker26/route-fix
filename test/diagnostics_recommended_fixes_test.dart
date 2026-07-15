import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/macos_fix_provider.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostic_issue.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostic_report.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostic_severity.dart';
import 'package:route_fix/domain/models/diagnostics/network_health.dart';
import 'package:route_fix/features/diagnostics/diagnostics_result_view_data.dart';

void main() {
  test('maps FixActions related to report issues into recommended fix cards', () {
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
        ),
      ],
      recommendations: const [],
    );

    final data = DiagnosticsResultViewData.fromReport(
      report,
      fixProvider: const MacOsFixProvider(),
    );

    expect(data.hasRecommendedFixes, isTrue);
    expect(
      data.recommendedFixes.map((f) => f.id),
      contains('disableIpv6'),
    );
    expect(
      data.recommendedFixes.map((f) => f.title),
      contains('Disable IPv6'),
    );
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
      fixProvider: const MacOsFixProvider(),
    );

    expect(data.recommendedFixes, isEmpty);
  });
}
