import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/models/diagnostics/diagnostic_issue.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import '../../domain/models/diagnostics/diagnostic_severity.dart';
import 'human_message.dart';

/// Presentation model for the results screen.
final class DiagnosticsResultViewData {
  const DiagnosticsResultViewData({
    required this.overallScore,
    required this.scoreLabel,
    required this.scoreSummary,
    required this.scoreTone,
    required this.confidence,
    required this.timestampLabel,
    required this.networkMetrics,
    required this.problems,
    required this.serviceImpacts,
    required this.technicalDetails,
    this.primaryFix,
    this.secondaryFixes = const [],
  });

  final int overallScore;
  final String scoreLabel;
  final String scoreSummary;
  final StatusBadgeTone scoreTone;
  final double confidence;
  final String timestampLabel;
  final List<NetworkMetricView> networkMetrics;
  final List<ProblemView> problems;
  final List<ServiceImpactView> serviceImpacts;
  final List<TechnicalDetailView> technicalDetails;
  final RecommendedFixView? primaryFix;
  final List<RecommendedFixView> secondaryFixes;

  bool get hasProblems => problems.isNotEmpty;
  bool get hasPrimaryFix => primaryFix != null;
  bool get hasSecondaryFixes => secondaryFixes.isNotEmpty;
  bool get hasNetworkMetrics => networkMetrics.isNotEmpty;

  factory DiagnosticsResultViewData.fromReport(
    DiagnosticReport report, {
    FixProvider? fixProvider,
  }) {
    final meta = report.metadata;
    final scoreTone = _toneForScore(report.health.score);

    final summary = report.issues.isEmpty
        ? 'Your routes look calm for this check. Everyday tools should feel responsive.'
        : report.issues.length == 1
            ? 'We found one route issue that may slow some developer tools.'
            : 'We found ${report.issues.length} route issues that may slow some developer tools.';

    final created = report.createdAt.toLocal();
    final timestamp =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} · '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    final problems = report.issues
        .map(
          (issue) => ProblemView(
            title: _friendlyIssueTitle(issue),
            detail: HumanMessage.fromProbeError(
              issue.description,
              fallback: 'Something on this network path isn’t responding well.',
            ),
            severity: HumanMessage.severityLabel(issue.severity.name),
            tone: _toneForSeverity(issue.severity),
            icon: _iconForIssue(issue.code ?? issue.id),
            technicalDetail: issue.description,
          ),
        )
        .toList(growable: false);

    final fixes = fixProvider == null
        ? (primary: null, secondary: const <RecommendedFixView>[])
        : selectRecommendedFixes(report: report, fixProvider: fixProvider);

    return DiagnosticsResultViewData(
      overallScore: report.health.score,
      scoreLabel: _friendlyScoreLabel(report.health.label, report.health.score),
      scoreSummary: report.health.summary ?? summary,
      scoreTone: scoreTone,
      confidence: report.confidence,
      timestampLabel: timestamp,
      networkMetrics: _networkMetricsFrom(meta),
      problems: problems,
      serviceImpacts: _serviceImpactsFrom(report),
      technicalDetails: _technicalDetailsFrom(report, meta),
      primaryFix: fixes.primary,
      secondaryFixes: fixes.secondary,
    );
  }

  /// One primary actionable fix + optional secondary actions.
  /// Never returns contradictory IPv6 enable/disable together.
  static ({RecommendedFixView? primary, List<RecommendedFixView> secondary})
      selectRecommendedFixes({
    required DiagnosticReport report,
    required FixProvider fixProvider,
  }) {
    final issueCodes = <String>{
      for (final issue in report.issues) ...[
        issue.id,
        if (issue.code != null) issue.code!,
      ],
    };
    if (issueCodes.isEmpty) {
      return (primary: null, secondary: const []);
    }

    final hasLatency = issueCodes.contains('ipv6_latency');
    final hasUnavailable = issueCodes.contains('ipv6_unavailable');

    final candidates = <RecommendedFixView>[];
    for (final action in fixProvider.availableActions()) {
      if (action.availability == FixAvailability.unsupported) continue;
      if (action.relatedIssueCodes.isEmpty) continue;
      if (!action.relatedIssueCodes.any(issueCodes.contains)) continue;

      // Contradiction guard.
      if (hasLatency && action.kind == FixActionKind.enableIpv6) continue;
      if (!hasLatency &&
          hasUnavailable &&
          action.kind == FixActionKind.disableIpv6) {
        continue;
      }
      if (hasLatency &&
          hasUnavailable &&
          action.kind == FixActionKind.enableIpv6) {
        continue;
      }

      final relatedIssues = report.issues
          .where(
            (issue) =>
                action.relatedIssueCodes.contains(issue.code ?? issue.id),
          )
          .toList(growable: false);
      if (relatedIssues.isEmpty) continue;

      candidates.add(
        _buildFixView(
          action: action,
          report: report,
          relatedIssues: relatedIssues,
        ),
      );
    }

    if (candidates.isEmpty) {
      return (primary: null, secondary: const []);
    }

    candidates.sort((a, b) {
      final applyCmp = (b.canConfirmApply ? 1 : 0) - (a.canConfirmApply ? 1 : 0);
      if (applyCmp != 0) return applyCmp;
      return b.priorityScore.compareTo(a.priorityScore);
    });

    return (
      primary: candidates.first,
      secondary: List.unmodifiable(candidates.skip(1)),
    );
  }

  static RecommendedFixView _buildFixView({
    required FixAction action,
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    final improvement = _estimatedImprovement(
      action: action,
      report: report,
      relatedIssues: relatedIssues,
    );
    return RecommendedFixView(
      id: action.id,
      kind: action.kind,
      title: action.title,
      description: action.description,
      why: _whyFor(action: action, report: report, relatedIssues: relatedIssues),
      whyThisRecommendation: _whyThisRecommendation(
        action: action,
        report: report,
        relatedIssues: relatedIssues,
      ),
      confidenceLabel: _confidenceLabel(
        report: report,
        relatedIssues: relatedIssues,
      ),
      estimatedImprovement: improvement,
      serviceImpacts: _fixServiceImpacts(action.kind, improvement),
      availabilityLabel: _availabilityLabel(action.availability),
      availabilityTone: _availabilityTone(action.availability),
      icon: _iconForFix(action.kind),
      canConfirmApply: action.availability == FixAvailability.available ||
          action.availability == FixAvailability.requiresElevation,
      requiresElevation:
          action.availability == FixAvailability.requiresElevation,
      priorityScore: _priorityScore(relatedIssues, action),
      backedByRuleIds:
          relatedIssues.map((issue) => issue.code ?? issue.id).toList(),
    );
  }

  static String _whyFor({
    required FixAction action,
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    if (action.kind == FixActionKind.disableIpv6) {
      final ipv4Ms = double.tryParse(
        report.metadata['ipv4_tcp_ms'] ?? report.metadata['ipv4_latency_ms'] ?? '',
      );
      final ipv6Ms = double.tryParse(
        report.metadata['ipv6_tcp_ms'] ?? report.metadata['ipv6_latency_ms'] ?? '',
      );
      if (ipv4Ms != null && ipv6Ms != null && ipv4Ms > 0 && ipv6Ms > ipv4Ms) {
        final ratio = ipv6Ms / ipv4Ms;
        final formatted = ratio >= 2
            ? ratio.round().toString()
            : ratio.toStringAsFixed(1);
        return 'IPv6 TCP connect is about $formatted× slower than IPv4 right now.';
      }
    }

    if (relatedIssues.isNotEmpty) {
      return HumanMessage.fromProbeError(
        relatedIssues.first.description,
        fallback: action.description,
      );
    }
    return action.description;
  }

  static String _whyThisRecommendation({
    required FixAction action,
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    return switch (action.kind) {
      FixActionKind.disableIpv6 =>
        'Preferring IPv4 can help apps skip a slow IPv6 TCP path and feel snappier for tools that use the network.',
      FixActionKind.enableIpv6 =>
        'Turning IPv6 back on can restore normal dual-stack routing when something disabled it earlier.',
      FixActionKind.flushDns =>
        'Clearing outdated DNS answers can help when names resolve incorrectly after network changes.',
      FixActionKind.openWarp =>
        'A quieter edge path can help when public routes are congested or unreliable.',
    };
  }

  static String _confidenceLabel({
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    var confidence = report.confidence;
    for (final issue in relatedIssues) {
      final parsed = double.tryParse(
        issue.metadata['rule_confidence'] ??
            issue.metadata['confidence_confidence'] ??
            '',
      );
      if (parsed != null && parsed > confidence) confidence = parsed;
    }
    return '${(confidence * 100).round()}%';
  }

  static String _estimatedImprovement({
    required FixAction action,
    required DiagnosticReport report,
    required List<DiagnosticIssue> relatedIssues,
  }) {
    if (action.kind == FixActionKind.disableIpv6) {
      final ipv4Ms = double.tryParse(
        report.metadata['ipv4_tcp_ms'] ?? report.metadata['ipv4_latency_ms'] ?? '',
      );
      final ipv6Ms = double.tryParse(
        report.metadata['ipv6_tcp_ms'] ?? report.metadata['ipv6_latency_ms'] ?? '',
      );
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

  static List<ServiceImpactView> _fixServiceImpacts(
    FixActionKind kind,
    String improvement,
  ) {
    final focus = switch (kind) {
      FixActionKind.disableIpv6 || FixActionKind.enableIpv6 => {
          'Git': improvement,
          'Python': improvement,
          'Docker': 'Medium',
          'AI APIs': improvement,
        },
      FixActionKind.flushDns => {
          'Git': 'Medium',
          'Python': 'Medium',
          'Docker': 'High',
          'AI APIs': 'Medium',
        },
      FixActionKind.openWarp => {
          'Git': 'Medium',
          'Python': 'Low',
          'Docker': 'Medium',
          'AI APIs': 'High',
        },
    };

    return [
      for (final entry in focus.entries)
        ServiceImpactView(
          name: entry.key,
          level: entry.value,
          label: HumanMessage.impactLabel(entry.value),
          icon: _iconForService(entry.key),
        ),
    ];
  }

  static List<ServiceImpactView> _serviceImpactsFrom(DiagnosticReport report) {
    final codes = {
      for (final issue in report.issues) issue.code ?? issue.id,
    };

    String levelFor({
      required bool hit,
      required String strong,
    }) {
      if (!hit) return 'None';
      return strong;
    }

    final git = levelFor(
      hit: codes.any((c) =>
          c.contains('github') || c.contains('ipv6') || c.contains('dns')),
      strong: codes.any((c) => c.contains('github')) ? 'High' : 'Medium',
    );
    final python = levelFor(
      hit: codes.any(
          (c) => c.contains('pypi') || c.contains('ipv6') || c.contains('dns')),
      strong: codes.any((c) => c.contains('pypi')) ? 'High' : 'Medium',
    );
    final docker = levelFor(
      hit: codes.any((c) => c.contains('dns') || c.contains('ipv6')),
      strong: codes.any((c) => c.contains('dns')) ? 'High' : 'Medium',
    );
    final ai = levelFor(
      hit: codes.any((c) =>
          c.contains('ipv6') || c.contains('dns') || c.contains('github')),
      strong: 'Medium',
    );

    return [
      ServiceImpactView(
        name: 'Git',
        level: git,
        label: HumanMessage.impactLabel(git),
        icon: _iconForService('Git'),
      ),
      ServiceImpactView(
        name: 'Python',
        level: python,
        label: HumanMessage.impactLabel(python),
        icon: _iconForService('Python'),
      ),
      ServiceImpactView(
        name: 'Docker',
        level: docker,
        label: HumanMessage.impactLabel(docker),
        icon: _iconForService('Docker'),
      ),
      ServiceImpactView(
        name: 'AI APIs',
        level: ai,
        label: HumanMessage.impactLabel(ai),
        icon: _iconForService('AI APIs'),
      ),
    ];
  }

  static List<NetworkMetricView> _networkMetricsFrom(Map<String, String> meta) {
    final metrics = <NetworkMetricView>[];

    final dnsMs = meta['dns_lookup_ms'];
    if (dnsMs != null || meta.containsKey('dns_success')) {
      final dnsOk = meta['dns_success'] != 'false';
      metrics.add(
        NetworkMetricView(
          title: 'DNS lookup',
          value: dnsOk
              ? (dnsMs != null ? '$dnsMs ms' : 'Resolved')
              : 'Failed',
          detail: dnsOk
              ? 'Name resolution time'
              : HumanMessage.fromProbeError(
                  meta['dns_error'],
                  fallback: 'Couldn’t resolve the hostname',
                ),
          tone: dnsOk ? StatusBadgeTone.success : StatusBadgeTone.error,
          icon: Icons.dns_outlined,
          technicalDetail: [
            if (dnsMs != null) 'dns_lookup_ms=$dnsMs',
            if (meta['dns_error'] != null) meta['dns_error']!,
          ].join('\n'),
        ),
      );
    }

    final ipv4Ok = meta['ipv4_success'] == 'true';
    final ipv4TcpMs = meta['ipv4_tcp_ms'] ?? meta['ipv4_latency_ms'];
    final ipv4DnsMs = meta['ipv4_dns_ms'];
    metrics.add(
      NetworkMetricView(
        title: 'IPv4 connect',
        value: ipv4Ok
            ? (ipv4TcpMs != null ? '$ipv4TcpMs ms' : 'Reachable')
            : 'Unavailable',
        detail: ipv4Ok
            ? 'TCP connect time'
            : HumanMessage.fromProbeError(
                meta['ipv4_error'],
                fallback: 'Couldn’t complete an IPv4 check',
              ),
        tone: ipv4Ok ? StatusBadgeTone.success : StatusBadgeTone.error,
        icon: Icons.public_rounded,
        technicalDetail: [
          if (ipv4DnsMs != null) 'DNS: $ipv4DnsMs ms',
          if (ipv4TcpMs != null) 'TCP: $ipv4TcpMs ms',
          if (meta['ipv4_address'] != null) 'Address: ${meta['ipv4_address']}',
          if (meta['ipv4_error'] != null) meta['ipv4_error']!,
        ].join('\n'),
      ),
    );

    final ipv6Ok = meta['ipv6_success'] == 'true';
    final ipv6TcpMs = meta['ipv6_tcp_ms'] ?? meta['ipv6_latency_ms'];
    final ipv6DnsMs = meta['ipv6_dns_ms'];
    if (meta.containsKey('ipv6_success') || ipv6TcpMs != null) {
      metrics.add(
        NetworkMetricView(
          title: 'IPv6 connect',
          value: ipv6Ok
              ? (ipv6TcpMs != null ? '$ipv6TcpMs ms' : 'Reachable')
              : 'Unavailable',
          detail: ipv6Ok
              ? 'TCP connect time'
              : HumanMessage.fromProbeError(
                  meta['ipv6_error'],
                  fallback: 'Couldn’t complete an IPv6 check',
                ),
          tone: ipv6Ok
              ? (ipv6TcpMs != null &&
                      ipv4TcpMs != null &&
                      (double.tryParse(ipv6TcpMs) ?? 0) >
                          (double.tryParse(ipv4TcpMs) ?? 0) * 2
                  ? StatusBadgeTone.warning
                  : StatusBadgeTone.success)
              : StatusBadgeTone.warning,
          icon: Icons.hub_outlined,
          technicalDetail: [
            if (ipv6DnsMs != null) 'DNS: $ipv6DnsMs ms',
            if (ipv6TcpMs != null) 'TCP: $ipv6TcpMs ms',
            if (meta['ipv6_address'] != null)
              'Address: ${meta['ipv6_address']}',
            if (meta['ipv6_error'] != null) meta['ipv6_error']!,
          ].join('\n'),
        ),
      );
    }

    final cfOk = meta['cloudflare_success'] != 'false';
    if (meta.containsKey('cloudflare_success') ||
        meta.containsKey('cloudflare_http_ms') ||
        meta.containsKey('cloudflare_latency_ms')) {
      final cfHttpMs = meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms'];
      metrics.add(
        NetworkMetricView(
          title: 'HTTPS response',
          value: cfOk
              ? (cfHttpMs != null ? '$cfHttpMs ms' : 'Reachable')
              : 'Unavailable',
          detail: cfOk
              ? 'HTTP status-line time (after DNS / TCP / TLS)'
              : HumanMessage.fromProbeError(
                  meta['cloudflare_error'],
                  fallback: 'Edge check didn’t complete',
                ),
          tone: cfOk ? StatusBadgeTone.success : StatusBadgeTone.warning,
          icon: Icons.cloud_outlined,
          technicalDetail: [
            if (meta['cloudflare_dns_ms'] != null)
              'DNS: ${meta['cloudflare_dns_ms']} ms',
            if (meta['cloudflare_tcp_ms'] != null)
              'TCP: ${meta['cloudflare_tcp_ms']} ms',
            if (meta['cloudflare_tls_ms'] != null)
              'TLS: ${meta['cloudflare_tls_ms']} ms',
            if (cfHttpMs != null) 'HTTP: $cfHttpMs ms',
            if (meta['cloudflare_http_status'] != null)
              'HTTP ${meta['cloudflare_http_status']}',
            if (meta['cloudflare_error'] != null) meta['cloudflare_error']!,
          ].join('\n'),
        ),
      );
    }

    return metrics;
  }

  static List<TechnicalDetailView> _technicalDetailsFrom(
    DiagnosticReport report,
    Map<String, String> meta,
  ) {
    final rows = <TechnicalDetailView>[
      TechnicalDetailView(
        label: 'Report ID',
        value: report.id,
      ),
      TechnicalDetailView(
        label: 'Checked at',
        value: report.createdAt.toUtc().toIso8601String(),
      ),
      if (report.duration != null)
        TechnicalDetailView(
          label: 'Duration',
          value: '${report.duration!.inMilliseconds} ms',
        ),
      for (final issue in report.issues)
        TechnicalDetailView(
          label: 'Rule ${issue.code ?? issue.id}',
          value: [
            issue.title,
            issue.description,
            if (issue.metadata['rule_confidence'] != null)
              'confidence=${issue.metadata['rule_confidence']}'
            else if (issue.metadata['confidence_confidence'] != null)
              'confidence=${issue.metadata['confidence_confidence']}',
          ].join(' · '),
        ),
      for (final entry in meta.entries)
        if (entry.key.contains('error') ||
            entry.key.contains('latency') ||
            entry.key.endsWith('_ms') ||
            entry.key.contains('address') ||
            entry.key.contains('status') ||
            entry.key.startsWith('rules_'))
          TechnicalDetailView(label: entry.key, value: entry.value),
    ];
    return rows;
  }

  static int _priorityScore(
    List<DiagnosticIssue> relatedIssues,
    FixAction action,
  ) {
    var score = 0;
    for (final issue in relatedIssues) {
      score += (issue.severity.index + 1) * 10;
    }
    if (action.availability == FixAvailability.available ||
        action.availability == FixAvailability.requiresElevation) {
      score += 20;
    }
    return score;
  }

  static String _friendlyIssueTitle(DiagnosticIssue issue) {
    final code = issue.code ?? issue.id;
    if (code.contains('ipv6_latency')) return 'IPv6 is slower than expected';
    if (code.contains('ipv6_unavailable')) return 'IPv6 isn’t available';
    if (code.contains('dns')) return 'Name lookup is having trouble';
    if (code.contains('github')) return 'GitHub is hard to reach';
    if (code.contains('pypi')) return 'Python packages may download slowly';
    return issue.title;
  }

  static String _friendlyScoreLabel(String label, int score) {
    if (score >= 85) return 'Looking good';
    if (score >= 70) return 'Mostly fine';
    if (score >= 55) return 'Needs attention';
    return 'Needs help';
  }

  static String _availabilityLabel(FixAvailability availability) {
    return switch (availability) {
      FixAvailability.available => 'Ready',
      FixAvailability.requiresElevation => 'Needs permission',
      FixAvailability.comingSoon => 'Coming soon',
      FixAvailability.unsupported => 'Unavailable here',
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

  static IconData _iconForService(String name) {
    return switch (name) {
      'Git' => Icons.merge_type_rounded,
      'Python' => Icons.terminal_rounded,
      'Docker' => Icons.inventory_2_outlined,
      'AI APIs' => Icons.auto_awesome_outlined,
      _ => Icons.apps_rounded,
    };
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
    if (code.contains('ipv6')) return Icons.settings_ethernet_rounded;
    if (code.contains('github')) return Icons.merge_type_rounded;
    if (code.contains('pypi')) return Icons.terminal_rounded;
    return Icons.info_outline_rounded;
  }
}

class NetworkMetricView {
  const NetworkMetricView({
    required this.title,
    required this.value,
    required this.detail,
    required this.tone,
    required this.icon,
    this.technicalDetail = '',
  });

  final String title;
  final String value;
  final String detail;
  final StatusBadgeTone tone;
  final IconData icon;
  final String technicalDetail;
}

class ProblemView {
  const ProblemView({
    required this.title,
    required this.detail,
    required this.severity,
    required this.tone,
    required this.icon,
    this.technicalDetail = '',
  });

  final String title;
  final String detail;
  final String severity;
  final StatusBadgeTone tone;
  final IconData icon;
  final String technicalDetail;
}

class ServiceImpactView {
  const ServiceImpactView({
    required this.name,
    required this.level,
    required this.label,
    required this.icon,
  });

  final String name;
  final String level;
  final String label;
  final IconData icon;
}

class TechnicalDetailView {
  const TechnicalDetailView({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class RecommendedFixView {
  const RecommendedFixView({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.why,
    required this.whyThisRecommendation,
    required this.confidenceLabel,
    required this.estimatedImprovement,
    required this.serviceImpacts,
    required this.availabilityLabel,
    required this.availabilityTone,
    required this.icon,
    required this.priorityScore,
    required this.backedByRuleIds,
    this.canConfirmApply = false,
    this.requiresElevation = false,
  });

  final String id;
  final FixActionKind kind;
  final String title;
  final String description;
  final String why;
  final String whyThisRecommendation;
  final String confidenceLabel;
  final String estimatedImprovement;
  final List<ServiceImpactView> serviceImpacts;
  final String availabilityLabel;
  final StatusBadgeTone availabilityTone;
  final IconData icon;
  final int priorityScore;
  final List<String> backedByRuleIds;
  final bool canConfirmApply;
  final bool requiresElevation;
}
