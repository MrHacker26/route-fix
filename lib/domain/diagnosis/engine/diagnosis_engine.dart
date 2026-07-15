import '../../models/diagnostics/diagnostic_issue.dart';
import '../../models/diagnostics/diagnostic_report.dart';
import '../../models/diagnostics/diagnostic_severity.dart';
import '../../models/diagnostics/recommendation.dart';
import '../rules/diagnosis_rule.dart';
import '../rules/diagnosis_rule_result.dart';
import '../rules/dns_failure_rule.dart';
import '../rules/github_connectivity_rule.dart';
import '../rules/ipv6_latency_rule.dart';
import '../rules/ipv6_unavailable_rule.dart';
import '../rules/pypi_latency_rule.dart';
import 'diagnosis_observations.dart';
import 'health_score_calculator.dart';

/// Runs every diagnosis rule against service outputs and builds a report.
///
/// Performs no network I/O.
final class DiagnosisEngine {
  DiagnosisEngine({
    DnsFailureRule? dnsFailureRule,
    Ipv6UnavailableRule? ipv6UnavailableRule,
    Ipv6LatencyRule? ipv6LatencyRule,
    GitHubConnectivityRule? githubConnectivityRule,
    PyPILatencyRule? pypiLatencyRule,
    HealthScoreCalculator? healthScoreCalculator,
    DateTime Function()? clock,
    String Function()? reportIdFactory,
  })  : _dnsFailureRule = dnsFailureRule ?? const DnsFailureRule(),
        _ipv6UnavailableRule =
            ipv6UnavailableRule ?? const Ipv6UnavailableRule(),
        _ipv6LatencyRule = ipv6LatencyRule ?? const Ipv6LatencyRule(),
        _githubConnectivityRule =
            githubConnectivityRule ?? const GitHubConnectivityRule(),
        _pypiLatencyRule = pypiLatencyRule ?? const PyPILatencyRule(),
        _healthScoreCalculator =
            healthScoreCalculator ?? const HealthScoreCalculator(),
        _clock = clock ?? DateTime.now,
        _reportIdFactory = reportIdFactory ?? _defaultReportId;

  final DnsFailureRule _dnsFailureRule;
  final Ipv6UnavailableRule _ipv6UnavailableRule;
  final Ipv6LatencyRule _ipv6LatencyRule;
  final GitHubConnectivityRule _githubConnectivityRule;
  final PyPILatencyRule _pypiLatencyRule;
  final HealthScoreCalculator _healthScoreCalculator;
  final DateTime Function() _clock;
  final String Function() _reportIdFactory;

  DiagnosticReport analyze(DiagnosisObservations observations) {
    final createdAt = _clock();
    final stopwatch = Stopwatch()..start();

    final evaluations = <_RuleEvaluation>[
      _evaluate(_dnsFailureRule, observations.dnsLookup),
      _evaluate(_ipv6UnavailableRule, observations.ipv6Connectivity),
      _evaluate(_ipv6LatencyRule, observations.ipv6Connectivity),
      _evaluate(_githubConnectivityRule, observations.githubProbe),
      _evaluate(_pypiLatencyRule, observations.pypiDiagnostics),
    ];

    stopwatch.stop();

    final issues = <DiagnosticIssue>[];
    final recommendations = <Recommendation>[];
    final resultOnly = <DiagnosisRuleResult>[];

    for (final evaluation in evaluations) {
      resultOnly.add(evaluation.result);
      if (!evaluation.result.failed) continue;

      final issue = _issueFrom(evaluation);
      issues.add(issue);

      final recommendation = evaluation.result.recommendation;
      if (recommendation != null) {
        recommendations.add(
          Recommendation(
            id: recommendation.id,
            title: recommendation.title,
            detail: recommendation.detail,
            priority: recommendation.priority,
            actionLabel: recommendation.actionLabel,
            relatedIssueIds: recommendation.relatedIssueIds.isEmpty
                ? [issue.id]
                : recommendation.relatedIssueIds,
            metadata: recommendation.metadata,
          ),
        );
      }
    }

    final confidence = _aggregateConfidence(resultOnly);
    final health = _healthScoreCalculator.calculate(
      results: resultOnly,
      failedCount: issues.length,
      checkedAt: createdAt,
    );

    return DiagnosticReport(
      id: _reportIdFactory(),
      createdAt: createdAt,
      health: health,
      confidence: confidence,
      issues: List.unmodifiable(issues),
      recommendations: List.unmodifiable(recommendations),
      duration: stopwatch.elapsed,
      metadata: {
        'rules_evaluated': '${evaluations.length}',
        'rules_failed': '${issues.length}',
      },
    );
  }

  _RuleEvaluation _evaluate<T>(DiagnosisRule<T> rule, T input) {
    return _RuleEvaluation(rule: rule, result: rule.evaluate(input));
  }

  DiagnosticIssue _issueFrom(_RuleEvaluation evaluation) {
    final recommendation = evaluation.result.recommendation;
    return DiagnosticIssue(
      id: evaluation.rule.id,
      title: recommendation?.title ?? evaluation.rule.name,
      description: recommendation?.detail ??
          'Diagnosis rule "${evaluation.rule.id}" failed.',
      severity: recommendation?.priority ?? DiagnosticSeverity.medium,
      code: evaluation.rule.id,
      metadata: {
        'confidence': evaluation.rule.name,
        'confidence_confidence': evaluation.result.confidence.toStringAsFixed(2),
      },
    );
  }

  double _aggregateConfidence(List<DiagnosisRuleResult> results) {
    if (results.isEmpty) return 0;
    final total = results.fold<double>(0, (sum, r) => sum + r.confidence);
    return (total / results.length).clamp(0.0, 1.0);
  }

  static String _defaultReportId() {
    return 'report-${DateTime.now().microsecondsSinceEpoch}';
  }
}

final class _RuleEvaluation {
  const _RuleEvaluation({
    required this.rule,
    required this.result,
  });

  final DiagnosisRule<dynamic> rule;
  final DiagnosisRuleResult result;
}
