import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostics.dart';

void main() {
  test('DiagnosticReport holds immutable diagnostic value types', () {
    const issue = DiagnosticIssue(
      id: 'gh-latency',
      title: 'GitHub latency elevated',
      description: 'Final hop slower than baseline',
      severity: DiagnosticSeverity.medium,
      target: 'api.github.com',
    );

    const recommendation = Recommendation(
      id: 'warm-path',
      title: 'Warm the GitHub path',
      detail: 'Retry off-peak or use a closer mirror',
      priority: DiagnosticSeverity.low,
      relatedIssueIds: ['gh-latency'],
    );

    final checkedAt = DateTime.utc(2026, 7, 15, 12);
    final report = DiagnosticReport(
      id: 'report-1',
      createdAt: checkedAt,
      health: NetworkHealth(
        score: 74,
        label: 'Fair',
        summary: 'One elevated path',
        checkedAt: checkedAt,
        metrics: const {'github_ms': 132},
      ),
      issues: const [issue],
      recommendations: const [recommendation],
      duration: const Duration(seconds: 18),
    );

    expect(report.health.score, 74);
    expect(report.issues.single.severity, DiagnosticSeverity.medium);
    expect(report.recommendations.single.relatedIssueIds, ['gh-latency']);
    expect(
      report,
      DiagnosticReport(
        id: 'report-1',
        createdAt: checkedAt,
        health: NetworkHealth(
          score: 74,
          label: 'Fair',
          summary: 'One elevated path',
          checkedAt: checkedAt,
          metrics: const {'github_ms': 132},
        ),
        issues: const [issue],
        recommendations: const [recommendation],
        duration: const Duration(seconds: 18),
      ),
    );
  });
}
