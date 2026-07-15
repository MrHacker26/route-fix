import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/models/diagnostics/diagnostic_issue.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import '../../domain/models/diagnostics/diagnostic_severity.dart';

/// Presentation model for the results screen — mapped from [DiagnosticReport].
final class DiagnosticsResultViewData {
  const DiagnosticsResultViewData({
    required this.overallScore,
    required this.scoreLabel,
    required this.scoreSummary,
    required this.scoreTone,
    required this.confidence,
    required this.timestampLabel,
    required this.latencyBars,
    required this.stabilityTrend,
    required this.metricCards,
    required this.issues,
    required this.recommendations,
    this.recommendedFixes = const [],
  });

  final int overallScore;
  final String scoreLabel;
  final String scoreSummary;
  final StatusBadgeTone scoreTone;
  final double confidence;
  final String timestampLabel;
  final List<LatencyBarView> latencyBars;
  final List<double> stabilityTrend;
  final List<MetricCardView> metricCards;
  final List<IssueView> issues;
  final List<RecommendationView> recommendations;
  final List<RecommendedFixView> recommendedFixes;

  bool get hasIssues => issues.isNotEmpty;
  bool get hasRecommendations => recommendations.isNotEmpty;
  bool get hasRecommendedFixes => recommendedFixes.isNotEmpty;
  bool get hasMetrics => metricCards.isNotEmpty;

  factory DiagnosticsResultViewData.fromReport(
    DiagnosticReport report, {
    FixProvider? fixProvider,
  }) {
    final meta = report.metadata;
    final scoreTone = _toneForScore(report.health.score);

    final summary = report.health.summary ??
        (report.issues.isEmpty
            ? 'No issues detected. Routes look calm for this run.'
            : '${report.issues.length} issue${report.issues.length == 1 ? '' : 's'} detected across probed services.');

    final created = report.createdAt.toLocal();
    final timestamp =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} · '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    final latencyBars = _latencyBarsFrom(meta);
    final trend = _trendFrom(report, latencyBars);
    final cards = _metricCardsFrom(report, meta);

    final issues = report.issues
        .map(
          (issue) => IssueView(
            title: issue.title,
            detail: issue.description,
            severity: issue.severity.name,
            tone: _toneForSeverity(issue.severity),
            icon: _iconForIssue(issue.code ?? issue.id),
          ),
        )
        .toList(growable: false);

    final recommendations = report.recommendations
        .map(
          (item) => RecommendationView(
            title: item.title,
            detail: item.detail,
            icon: _iconForRecommendation(item.id),
          ),
        )
        .toList(growable: false);

    final recommendedFixes = fixProvider == null
        ? const <RecommendedFixView>[]
        : recommendedFixesFor(report: report, fixProvider: fixProvider);

    return DiagnosticsResultViewData(
      overallScore: report.health.score,
      scoreLabel: report.health.label,
      scoreSummary: summary,
      scoreTone: scoreTone,
      confidence: report.confidence,
      timestampLabel: timestamp,
      latencyBars: latencyBars,
      stabilityTrend: trend,
      metricCards: cards,
      issues: issues,
      recommendations: recommendations,
      recommendedFixes: recommendedFixes,
    );
  }

  /// Maps host [FixAction]s whose related issue codes appear in [report].
  static List<RecommendedFixView> recommendedFixesFor({
    required DiagnosticReport report,
    required FixProvider fixProvider,
  }) {
    final issueCodes = <String>{
      for (final issue in report.issues) ...[
        issue.id,
        if (issue.code != null) issue.code!,
      ],
    };

    if (issueCodes.isEmpty) return const [];

    final views = <RecommendedFixView>[];
    for (final action in fixProvider.availableActions()) {
      if (action.availability == FixAvailability.unsupported) continue;
      if (!action.relatedIssueCodes.any(issueCodes.contains)) continue;

      final relatedIssues = report.issues
          .where(
            (issue) => action.relatedIssueCodes.contains(issue.code ?? issue.id),
          )
          .toList(growable: false);

      views.add(
        RecommendedFixView(
          id: action.id,
          kind: action.kind,
          title: action.title,
          description: action.description,
          why: _whyFor(
            action: action,
            report: report,
            relatedIssues: relatedIssues,
          ),
          confidenceLabel: _confidenceLabel(
            report: report,
            relatedIssues: relatedIssues,
          ),
          estimatedImprovement: _estimatedImprovement(
            action: action,
            report: report,
            relatedIssues: relatedIssues,
          ),
          availabilityLabel: _availabilityLabel(action.availability),
          availabilityTone: _availabilityTone(action.availability),
          icon: _iconForFix(action.kind),
          canConfirmApply: action.availability == FixAvailability.available ||
              action.availability == FixAvailability.requiresElevation,
          requiresElevation:
              action.availability == FixAvailability.requiresElevation,
        ),
      );
    }
    return List.unmodifiable(views);
  }

  static String _whyFor({
    required FixAction action,
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    if (action.kind == FixActionKind.disableIpv6) {
      final ipv4Ms = double.tryParse(report.metadata['ipv4_latency_ms'] ?? '');
      final ipv6Ms = double.tryParse(report.metadata['ipv6_latency_ms'] ?? '');
      if (ipv4Ms != null && ipv6Ms != null && ipv4Ms > 0 && ipv6Ms > ipv4Ms) {
        final ratio = ipv6Ms / ipv4Ms;
        final formatted = ratio >= 10
            ? ratio.round().toString()
            : (ratio >= 2
                ? ratio.round().toString()
                : ratio.toStringAsFixed(1));
        return 'Your IPv6 latency is $formatted× higher than IPv4.';
      }
    }

    if (relatedIssues.isNotEmpty) {
      return relatedIssues.first.description;
    }

    return action.description;
  }

  static String _confidenceLabel({
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    var confidence = report.confidence;
    for (final issue in relatedIssues) {
      final parsed = double.tryParse(issue.metadata['rule_confidence'] ?? '');
      if (parsed != null && parsed > confidence) {
        confidence = parsed;
      }
    }
    return '${(confidence * 100).round()}%';
  }

  static String _estimatedImprovement({
    required FixAction action,
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    if (action.kind == FixActionKind.disableIpv6) {
      final ipv4Ms = double.tryParse(report.metadata['ipv4_latency_ms'] ?? '');
      final ipv6Ms = double.tryParse(report.metadata['ipv6_latency_ms'] ?? '');
      if (ipv4Ms != null && ipv6Ms != null && ipv4Ms > 0) {
        final ratio = ipv6Ms / ipv4Ms;
        if (ratio >= 5) return 'High';
        if (ratio >= 2) return 'Medium';
        return 'Low';
      }
    }

    if (relatedIssues.isEmpty) return 'Medium';
    final worst = relatedIssues
        .map((issue) => issue.severity)
        .reduce((a, b) => a.index >= b.index ? a : b);
    return switch (worst) {
      DiagnosticSeverity.critical || DiagnosticSeverity.high => 'High',
      DiagnosticSeverity.medium => 'Medium',
      DiagnosticSeverity.low || DiagnosticSeverity.info => 'Low',
    };
  }

  static String _availabilityLabel(FixAvailability availability) {
    return switch (availability) {
      FixAvailability.available => 'Ready',
      FixAvailability.requiresElevation => 'Needs admin',
      FixAvailability.comingSoon => 'Coming soon',
      FixAvailability.unsupported => 'Unsupported',
    };
  }

  static StatusBadgeTone _availabilityTone(FixAvailability availability) {
    return switch (availability) {
      FixAvailability.available => StatusBadgeTone.success,
      FixAvailability.requiresElevation => StatusBadgeTone.warning,
      FixAvailability.comingSoon => StatusBadgeTone.neutral,
      FixAvailability.unsupported => StatusBadgeTone.neutral,
    };
  }

  static IconData _iconForFix(FixActionKind kind) {
    return switch (kind) {
      FixActionKind.disableIpv6 || FixActionKind.enableIpv6 =>
        Icons.settings_ethernet_rounded,
      FixActionKind.flushDns => Icons.dns_outlined,
      FixActionKind.openWarp => Icons.travel_explore_rounded,
    };
  }

  static List<LatencyBarView> _latencyBarsFrom(Map<String, String> meta) {
    final bars = <LatencyBarView>[];

    final ipv4Ms = double.tryParse(meta['ipv4_latency_ms'] ?? '');
    if (ipv4Ms != null) {
      bars.add(
        LatencyBarView(
          label: 'IPv4',
          ms: ipv4Ms,
          tone: meta['ipv4_success'] == 'true'
              ? StatusBadgeTone.success
              : StatusBadgeTone.warning,
        ),
      );
    }

    final cfMs = double.tryParse(meta['cloudflare_latency_ms'] ?? '');
    if (cfMs != null) {
      bars.add(
        LatencyBarView(
          label: 'CF',
          ms: cfMs,
          tone: meta['cloudflare_success'] == 'true'
              ? StatusBadgeTone.success
              : StatusBadgeTone.warning,
        ),
      );
    }

    // Stable placeholders derived from available metrics when sparse.
    if (bars.isEmpty) {
      final rulesFailed = double.tryParse(meta['rules_failed'] ?? '0') ?? 0;
      bars.addAll([
        LatencyBarView(
          label: 'DNS',
          ms: rulesFailed > 0 ? 80 : 24,
          tone: rulesFailed > 0 ? StatusBadgeTone.warning : StatusBadgeTone.success,
        ),
        const LatencyBarView(
          label: 'Path',
          ms: 36,
          tone: StatusBadgeTone.info,
        ),
      ]);
    }

    return bars;
  }

  static List<double> _trendFrom(
    DiagnosticReport report,
    List<LatencyBarView> bars,
  ) {
    if (bars.isNotEmpty) {
      return [
        for (var i = 0; i < 8; i++)
          bars[i % bars.length].ms * (0.7 + (i * 0.05)),
      ];
    }
    final score = report.health.score.toDouble();
    return [
      score * 0.4,
      score * 0.45,
      score * 0.42,
      score * 0.5,
      score * 0.48,
      score * 0.55,
      score * 0.52,
      score * 0.58,
    ];
  }

  static List<MetricCardView> _metricCardsFrom(
    DiagnosticReport report,
    Map<String, String> meta,
  ) {
    final cards = <MetricCardView>[];

    cards.add(
      MetricCardView(
        title: 'Confidence',
        value: '${(report.confidence * 100).round()}%',
        detail: 'Aggregate rule confidence',
        tone: report.confidence >= 0.75
            ? StatusBadgeTone.success
            : StatusBadgeTone.warning,
        icon: Icons.insights_outlined,
        spark: [
          report.confidence * 40,
          report.confidence * 55,
          report.confidence * 50,
          report.confidence * 70,
          report.confidence * 65,
          report.confidence * 80,
          report.confidence * 90,
          report.confidence * 100,
        ],
      ),
    );

    final ipv4Ok = meta['ipv4_success'] == 'true';
    cards.add(
      MetricCardView(
        title: 'IPv4',
        value: ipv4Ok ? (meta['ipv4_latency_ms'] != null ? '${meta['ipv4_latency_ms']} ms' : 'OK') : 'Fail',
        detail: ipv4Ok
            ? (meta['ipv4_address'] ?? 'Reachable')
            : (meta['ipv4_error'] ?? 'Unavailable'),
        tone: ipv4Ok ? StatusBadgeTone.success : StatusBadgeTone.error,
        icon: Icons.filter_1_rounded,
        spark: ipv4Ok ? const [8, 9, 8, 7, 9, 8, 8, 7] : const [4, 3, 2, 1, 2, 1, 0, 0],
      ),
    );

    final cfOk = meta['cloudflare_success'] != 'false';
    final cfStatus = meta['cloudflare_http_status'];
    cards.add(
      MetricCardView(
        title: 'Cloudflare',
        value: cfStatus != null ? 'HTTP $cfStatus' : (cfOk ? 'OK' : 'Fail'),
        detail: meta['cloudflare_latency_ms'] != null
            ? '${meta['cloudflare_latency_ms']} ms edge'
            : (meta['cloudflare_error'] ?? 'Edge probe'),
        tone: cfOk ? StatusBadgeTone.success : StatusBadgeTone.warning,
        icon: Icons.cloud_outlined,
        spark: const [16, 17, 15, 18, 16, 19, 17, 18],
      ),
    );

    for (final entry in report.health.metrics.entries.take(3)) {
      cards.add(
        MetricCardView(
          title: _titleCase(entry.key),
          value: entry.value == entry.value.roundToDouble()
              ? '${entry.value.round()}'
              : entry.value.toStringAsFixed(1),
          detail: 'Network metric',
          tone: StatusBadgeTone.info,
          icon: Icons.speed_outlined,
          spark: [
            entry.value * 0.6,
            entry.value * 0.7,
            entry.value * 0.65,
            entry.value * 0.8,
            entry.value * 0.75,
            entry.value * 0.9,
            entry.value * 0.85,
            entry.value,
          ],
        ),
      );
    }

    final rulesFailed = meta['rules_failed'];
    if (rulesFailed != null) {
      final failed = int.tryParse(rulesFailed) ?? 0;
      cards.add(
        MetricCardView(
          title: 'Rules',
          value: '$failed failed',
          detail: '${meta['rules_evaluated'] ?? '—'} evaluated',
          tone: failed == 0 ? StatusBadgeTone.success : StatusBadgeTone.warning,
          icon: Icons.rule_folder_outlined,
          spark: failed == 0
              ? const [1, 1, 1, 1, 1, 1, 1, 1]
              : const [1, 2, 2, 3, 3, 4, 4, 5],
        ),
      );
    }

    return cards;
  }

  static String _titleCase(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static StatusBadgeTone _toneForScore(int score) {
    if (score >= 75) return StatusBadgeTone.success;
    if (score >= 55) return StatusBadgeTone.warning;
    return StatusBadgeTone.error;
  }

  static StatusBadgeTone _toneForSeverity(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.info => StatusBadgeTone.info,
      DiagnosticSeverity.low => StatusBadgeTone.neutral,
      DiagnosticSeverity.medium => StatusBadgeTone.warning,
      DiagnosticSeverity.high || DiagnosticSeverity.critical =>
        StatusBadgeTone.error,
    };
  }

  static IconData _iconForIssue(String code) {
    if (code.contains('dns')) return Icons.dns_outlined;
    if (code.contains('ipv6')) return Icons.link_off_rounded;
    if (code.contains('github')) return Icons.south_east_rounded;
    if (code.contains('pypi')) return Icons.inventory_2_outlined;
    return Icons.warning_amber_rounded;
  }

  static IconData _iconForRecommendation(String id) {
    if (id.contains('ipv6')) return Icons.settings_ethernet_rounded;
    if (id.contains('github')) return Icons.bolt_outlined;
    if (id.contains('dns')) return Icons.verified_outlined;
    if (id.contains('pypi')) return Icons.inventory_2_outlined;
    return Icons.lightbulb_outline_rounded;
  }
}

class LatencyBarView {
  const LatencyBarView({
    required this.label,
    required this.ms,
    required this.tone,
  });

  final String label;
  final double ms;
  final StatusBadgeTone tone;
}

class MetricCardView {
  const MetricCardView({
    required this.title,
    required this.value,
    required this.detail,
    required this.tone,
    required this.icon,
    required this.spark,
  });

  final String title;
  final String value;
  final String detail;
  final StatusBadgeTone tone;
  final IconData icon;
  final List<double> spark;
}

class IssueView {
  const IssueView({
    required this.title,
    required this.detail,
    required this.severity,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String detail;
  final String severity;
  final StatusBadgeTone tone;
  final IconData icon;
}

class RecommendationView {
  const RecommendationView({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

/// Presentation model for an Auto Fix suggestion on the results screen.
class RecommendedFixView {
  const RecommendedFixView({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.why,
    required this.confidenceLabel,
    required this.estimatedImprovement,
    required this.availabilityLabel,
    required this.availabilityTone,
    required this.icon,
    this.canConfirmApply = false,
    this.requiresElevation = false,
  });

  final String id;
  final FixActionKind kind;
  final String title;
  final String description;

  /// Evidence-backed explanation shown under "Why?".
  final String why;

  /// Display confidence, e.g. `96%`.
  final String confidenceLabel;

  /// Expected impact label: High / Medium / Low.
  final String estimatedImprovement;

  final String availabilityLabel;
  final StatusBadgeTone availabilityTone;
  final IconData icon;

  /// Whether the Apply Fix confirmation flow can be opened.
  final bool canConfirmApply;

  /// Whether confirming later will typically need elevation.
  final bool requiresElevation;
}
