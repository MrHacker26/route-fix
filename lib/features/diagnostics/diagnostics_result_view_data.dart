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
        ? 'All clear.'
        : report.issues.length == 1
            ? 'One path looks slower than usual.'
            : 'A few paths look slower than usual.';

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
              fallback: 'Couldn’t fully verify this path.',
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
      scoreLabel: HumanMessage.scoreBadge(report.health.score),
      scoreSummary: _friendlyHealthSummary(report.health.summary, summary),
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

  static String _friendlyHealthSummary(String? domainSummary, String fallback) {
    final raw = domainSummary?.trim() ?? '';
    if (raw.isEmpty) return fallback;
    final lower = raw.toLowerCase();
    if (lower.contains('all diagnosis rules passed') ||
        lower.contains('rules passed')) {
      return 'All clear.';
    }
    if (RegExp(r'^\d+\s+issues?\s+detected').hasMatch(lower)) {
      return fallback;
    }
    return raw;
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

    // Never recommend Auto Fix without strong evidence.
    final hasStrongEvidence = report.confidence >= 0.85 ||
        report.issues.any((issue) {
          final parsed = double.tryParse(
            issue.metadata['rule_confidence'] ??
                issue.metadata['confidence'] ??
                '',
          );
          return parsed != null && parsed >= 0.85;
        });
    if (!hasStrongEvidence) {
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
        return 'IPv6 is about $formatted× slower than IPv4 right now.';
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
        'Use IPv4 when IPv6 is clearly slower or unavailable.',
      FixActionKind.enableIpv6 =>
        'Return to normal settings if IPv6 was switched off.',
      FixActionKind.flushDns =>
        'Clear outdated name lookups after network changes.',
      FixActionKind.changeDnsCloudflare =>
        'Use Cloudflare resolvers when name lookup fails.',
      FixActionKind.openWarp =>
        'Try WARP when public routes feel congested.',
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
    return HumanMessage.confidenceStrength(confidence);
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
      FixActionKind.changeDnsCloudflare => {
          'Git': 'High',
          'Python': 'High',
          'Docker': 'Medium',
          'AI APIs': 'High',
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
          label: HumanMessage.fixImpactLabel(entry.value),
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
        label: HumanMessage.feltImpactLabel(git),
        icon: _iconForService('Git'),
      ),
      ServiceImpactView(
        name: 'Python',
        level: python,
        label: HumanMessage.feltImpactLabel(python),
        icon: _iconForService('Python'),
      ),
      ServiceImpactView(
        name: 'Docker',
        level: docker,
        label: HumanMessage.feltImpactLabel(docker),
        icon: _iconForService('Docker'),
      ),
      ServiceImpactView(
        name: 'AI APIs',
        level: ai,
        label: HumanMessage.feltImpactLabel(ai),
        icon: _iconForService('AI APIs'),
      ),
    ];
  }

  static List<NetworkMetricView> _networkMetricsFrom(Map<String, String> meta) {
    final metrics = <NetworkMetricView>[];

    // DNS
    final dnsOk = meta['dns_success'] == 'true';
    final dnsMs = meta['dns_lookup_ms'];
    final dnsKnown = meta.containsKey('dns_success') || dnsMs != null;
    metrics.add(
      NetworkMetricView(
        title: 'DNS',
        value: !dnsKnown
            ? '— Not checked'
            : dnsOk
                ? (dnsMs != null ? '✓ $dnsMs ms' : '✓ Resolved')
                : '✕ Unavailable',
        detail: !dnsKnown
            ? 'Not checked in this scan.'
            : dnsOk
                ? 'Name lookup completed.'
                : HumanMessage.fromProbeError(
                    meta['dns_error'],
                    fallback: 'Couldn’t verify DNS.',
                  ),
        tone: !dnsKnown
            ? StatusBadgeTone.neutral
            : dnsOk
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        icon: Icons.dns_outlined,
        technicalDetail: [
          if (dnsMs != null) 'DNS lookup: $dnsMs ms',
          if (meta['dns_error'] != null) meta['dns_error']!,
        ].join('\n'),
      ),
    );

    // IPv4
    final ipv4Ok = meta['ipv4_success'] == 'true';
    final ipv4TcpMs = meta['ipv4_tcp_ms'] ?? meta['ipv4_latency_ms'];
    final ipv4DnsMs = meta['ipv4_dns_ms'];
    final ipv4Known = meta.containsKey('ipv4_success') || ipv4TcpMs != null;
    metrics.add(
      NetworkMetricView(
        title: 'IPv4',
        value: !ipv4Known
            ? '— Not checked'
            : ipv4Ok
                ? (ipv4TcpMs != null
                    ? '✓ Connected · $ipv4TcpMs ms'
                    : '✓ Connected')
                : '✕ Unavailable',
        detail: !ipv4Known
            ? 'Not checked in this scan.'
            : ipv4Ok
                ? 'Connected.'
                : HumanMessage.fromProbeError(
                    meta['ipv4_error'],
                    fallback: 'Couldn’t verify IPv4.',
                  ),
        tone: !ipv4Known
            ? StatusBadgeTone.neutral
            : ipv4Ok
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        icon: Icons.filter_1_rounded,
        technicalDetail: [
          if (ipv4DnsMs != null) 'DNS: $ipv4DnsMs ms',
          if (ipv4TcpMs != null) 'TCP: $ipv4TcpMs ms',
          if (meta['ipv4_address'] != null) 'IP: ${meta['ipv4_address']}',
          if (meta['ipv4_error'] != null) meta['ipv4_error']!,
        ].join('\n'),
      ),
    );

    // IPv6 — never invent success
    final ipv6Ok = meta['ipv6_success'] == 'true';
    final ipv6TcpMs = meta['ipv6_tcp_ms'] ?? meta['ipv6_latency_ms'];
    final ipv6DnsMs = meta['ipv6_dns_ms'];
    final ipv6Error = meta['ipv6_error'] ?? '';
    final ipv6Known = meta.containsKey('ipv6_success') ||
        ipv6TcpMs != null ||
        ipv6Error.isNotEmpty;
    final noNativeIpv6 = ipv6Known &&
        !ipv6Ok &&
        (ipv6Error.toLowerCase().contains('no ipv6 address') ||
            ipv6Error.toLowerCase().contains('no ipv6 route') ||
            ipv6Error.toLowerCase().contains('no native'));
    metrics.add(
      NetworkMetricView(
        title: 'IPv6',
        value: !ipv6Known
            ? '— Not checked'
            : ipv6Ok
                ? (ipv6TcpMs != null
                    ? '✓ Online · $ipv6TcpMs ms'
                    : '✓ Online')
                : (noNativeIpv6 ? '— Idle' : '✕ Unavailable'),
        detail: !ipv6Known
            ? 'Not checked in this scan.'
            : ipv6Ok
                ? 'IPv6 is available.'
                : (noNativeIpv6
                    ? 'No IPv6 on this network.'
                    : HumanMessage.fromProbeError(
                        meta['ipv6_error'],
                        fallback: 'Couldn’t verify IPv6.',
                      )),
        tone: !ipv6Known
            ? StatusBadgeTone.neutral
            : ipv6Ok
                ? StatusBadgeTone.success
                : (noNativeIpv6
                    ? StatusBadgeTone.neutral
                    : StatusBadgeTone.warning),
        icon: Icons.filter_6_rounded,
        technicalDetail: [
          if (ipv6DnsMs != null) 'DNS: $ipv6DnsMs ms',
          if (ipv6TcpMs != null) 'TCP: $ipv6TcpMs ms',
          if (meta['ipv6_address'] != null) 'IP: ${meta['ipv6_address']}',
          if (meta['ipv6_error'] != null) meta['ipv6_error']!,
        ].join('\n'),
      ),
    );

    // TLS
    final cfOk = meta['cloudflare_success'] == 'true';
    final tlsMs = meta['cloudflare_tls_ms'];
    final tlsKnown = cfOk || tlsMs != null || meta['cloudflare_error'] != null;
    metrics.add(
      NetworkMetricView(
        title: 'TLS',
        value: !tlsKnown
            ? '— Not checked'
            : cfOk
                ? (tlsMs != null ? '✓ $tlsMs ms' : '✓ OK')
                : '✕ Unavailable',
        detail: !tlsKnown
            ? 'Not checked in this scan.'
            : cfOk
                ? 'Secure connection completed.'
                : HumanMessage.fromProbeError(
                    meta['cloudflare_error'],
                    fallback: 'Couldn’t verify the secure link.',
                  ),
        tone: !tlsKnown
            ? StatusBadgeTone.neutral
            : cfOk
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        icon: Icons.lock_outline_rounded,
        technicalDetail: [
          if (tlsMs != null) 'TLS: $tlsMs ms',
          if (meta['cloudflare_error'] != null) meta['cloudflare_error']!,
        ].join('\n'),
      ),
    );

    // HTTPS
    final cfHttpMs = meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms'];
    final cfStatus = meta['cloudflare_http_status'];
    final cfStatusCode = int.tryParse(cfStatus ?? '');
    final httpsKnown = meta.containsKey('cloudflare_success') ||
        cfStatus != null ||
        cfHttpMs != null;
    final httpsValue = !httpsKnown
        ? '— Not checked'
        : !cfOk
            ? '✕ Unavailable'
            : (cfStatusCode != null &&
                    cfStatusCode >= 200 &&
                    cfStatusCode < 400
                ? '✓ $cfStatusCode OK'
                : cfStatusCode != null
                    ? '✓ $cfStatusCode'
                    : (cfHttpMs != null ? '✓ $cfHttpMs ms' : '✓ Verified'));
    metrics.add(
      NetworkMetricView(
        title: 'HTTPS',
        value: httpsValue,
        detail: !httpsKnown
            ? 'Not checked in this scan.'
            : cfOk
                ? 'HTTPS looks good.'
                : HumanMessage.fromProbeError(
                    meta['cloudflare_error'],
                    fallback: 'Couldn’t verify HTTPS.',
                  ),
        tone: !httpsKnown
            ? StatusBadgeTone.neutral
            : cfOk
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        icon: Icons.https_outlined,
        technicalDetail: [
          if (meta['cloudflare_dns_ms'] != null)
            'DNS: ${meta['cloudflare_dns_ms']} ms',
          if (meta['cloudflare_tcp_ms'] != null)
            'TCP: ${meta['cloudflare_tcp_ms']} ms',
          if (meta['cloudflare_tls_ms'] != null)
            'TLS: ${meta['cloudflare_tls_ms']} ms',
          if (cfHttpMs != null) 'HTTP: $cfHttpMs ms',
          if (cfStatus != null) 'Status: $cfStatus',
          if (meta['cloudflare_error'] != null) meta['cloudflare_error']!,
        ].join('\n'),
      ),
    );

    return metrics;
  }

  static List<TechnicalDetailView> _technicalDetailsFrom(
    DiagnosticReport report,
    Map<String, String> meta,
  ) {
    final rows = <TechnicalDetailView>[
      TechnicalDetailView(
        label: 'Run',
        value: report.id,
      ),
      TechnicalDetailView(
        label: 'Time',
        value: report.createdAt.toLocal().toString(),
      ),
      if (report.duration != null)
        TechnicalDetailView(
          label: 'Scan duration',
          value: '${report.duration!.inMilliseconds} ms',
        ),
      const TechnicalDetailView(label: '— DNS —', value: ''),
      if (meta['dns_lookup_ms'] != null)
        TechnicalDetailView(label: 'DNS lookup', value: '${meta['dns_lookup_ms']} ms'),
      if (meta['dns_success'] != null)
        TechnicalDetailView(label: 'DNS status', value: meta['dns_success']!),
      if (meta['dns_error'] != null)
        TechnicalDetailView(label: 'DNS failure', value: meta['dns_error']!),
      const TechnicalDetailView(label: '— TCP —', value: ''),
      if (meta['ipv4_tcp_ms'] != null || meta['ipv4_latency_ms'] != null)
        TechnicalDetailView(
          label: 'IPv4 TCP',
          value: '${meta['ipv4_tcp_ms'] ?? meta['ipv4_latency_ms']} ms',
        ),
      if (meta['ipv4_address'] != null)
        TechnicalDetailView(label: 'IPv4 address', value: meta['ipv4_address']!),
      if (meta['ipv4_error'] != null)
        TechnicalDetailView(label: 'IPv4 failure', value: meta['ipv4_error']!),
      if (meta['ipv6_tcp_ms'] != null || meta['ipv6_latency_ms'] != null)
        TechnicalDetailView(
          label: 'IPv6 TCP',
          value: '${meta['ipv6_tcp_ms'] ?? meta['ipv6_latency_ms']} ms',
        ),
      if (meta['ipv6_address'] != null)
        TechnicalDetailView(label: 'IPv6 address', value: meta['ipv6_address']!),
      if (meta['ipv6_error'] != null)
        TechnicalDetailView(label: 'IPv6 failure', value: meta['ipv6_error']!),
      const TechnicalDetailView(label: '— TLS / HTTP —', value: ''),
      if (meta['cloudflare_tls_ms'] != null)
        TechnicalDetailView(
          label: 'TLS handshake',
          value: '${meta['cloudflare_tls_ms']} ms',
        ),
      if (meta['cloudflare_http_ms'] != null ||
          meta['cloudflare_latency_ms'] != null)
        TechnicalDetailView(
          label: 'HTTP response',
          value:
              '${meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms']} ms',
        ),
      if (meta['cloudflare_http_status'] != null)
        TechnicalDetailView(
          label: 'HTTP status',
          value: meta['cloudflare_http_status']!,
        ),
      if (meta['github_http_status'] != null)
        TechnicalDetailView(
          label: 'GitHub status',
          value: meta['github_http_status']!,
        ),
      if (meta['cloudflare_error'] != null)
        TechnicalDetailView(
          label: 'HTTPS failure',
          value: meta['cloudflare_error']!,
        ),
      if (report.issues.isNotEmpty) ...[
        const TechnicalDetailView(label: '— Rules —', value: ''),
        for (final issue in report.issues)
          TechnicalDetailView(
            label: issue.code ?? issue.id,
            value: [
              issue.title,
              issue.description,
              if (issue.metadata['rule_confidence'] != null)
                'evidence=${HumanMessage.confidenceStrength(double.tryParse(issue.metadata['rule_confidence']!) ?? 0)}',
            ].join(' · '),
          ),
      ],
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
    if (code.contains('ipv6_latency')) {
      return 'IPv6 is slower than expected';
    }
    if (code.contains('ipv6_unavailable')) {
      return 'Couldn’t verify IPv6';
    }
    if (code.contains('dns')) return 'Name lookup needs a look';
    if (code.contains('github')) return 'GitHub took longer than expected';
    if (code.contains('pypi')) return 'PyPI feels slow';
    return issue.title;
  }

  static String _availabilityLabel(FixAvailability availability) {
    return switch (availability) {
      FixAvailability.available => 'Ready',
      FixAvailability.requiresElevation => 'Needs password',
      FixAvailability.comingSoon => 'Soon',
      FixAvailability.unsupported => 'Unavailable',
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
      FixActionKind.flushDns ||
      FixActionKind.changeDnsCloudflare =>
        Icons.dns_outlined,
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

  /// Evidence strength tone — independent of health score coloring.
  static StatusBadgeTone toneForConfidence(double confidence) {
    if (confidence >= 0.85) return StatusBadgeTone.success;
    if (confidence >= 0.6) return StatusBadgeTone.info;
    return StatusBadgeTone.warning;
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
