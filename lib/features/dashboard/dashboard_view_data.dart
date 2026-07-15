import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/diagnostics/diagnostic_issue.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import '../../domain/models/diagnostics/diagnostic_severity.dart';
import '../diagnostics/human_message.dart';

/// Presentation model for the desktop command-center dashboard.
final class DashboardViewData {
  const DashboardViewData({
    required this.healthScore,
    required this.healthLabel,
    required this.healthDetail,
    required this.healthTone,
    required this.confidenceLabel,
    required this.canStartWorking,
    required this.recommendationTitle,
    required this.recommendationDetail,
    required this.recommendationTone,
    required this.recommendationAction,
    required this.networkRows,
    required this.services,
    required this.recentScan,
    required this.technicalGroups,
    required this.scannedAtLabel,
  });

  final int healthScore;
  final String healthLabel;
  final String healthDetail;
  final StatusBadgeTone healthTone;
  final String confidenceLabel;

  /// Calm one-liner answering “Can I start working?”
  final String canStartWorking;

  final String recommendationTitle;
  final String recommendationDetail;
  final StatusBadgeTone recommendationTone;

  /// Optional next action when evidence supports one.
  final String? recommendationAction;

  final List<NetworkSnapshotRow> networkRows;
  final List<DeveloperServiceRow> services;
  final RecentScanView recentScan;
  final List<TechnicalGroupView> technicalGroups;
  final String scannedAtLabel;

  factory DashboardViewData.fromReport(DiagnosticReport report) {
    final meta = report.metadata;
    final healthTone = _toneForScore(report.health.score);
    final healthLabel = HumanMessage.scoreBadge(report.health.score);

    final healthDetail = () {
      final raw = report.health.summary?.trim() ?? '';
      if (raw.toLowerCase().contains('all diagnosis rules passed') ||
          report.issues.isEmpty) {
        return 'No routing issues detected.';
      }
      if (RegExp(r'^\d+\s+issues?\s+detected', caseSensitive: false)
          .hasMatch(raw)) {
        return 'A few paths may need attention.';
      }
      return raw.isEmpty ? 'Based on your latest scan.' : raw;
    }();

    final canStartWorking = report.issues.isEmpty
        ? 'You can start working.'
        : report.issues.any(
            (i) =>
                i.severity == DiagnosticSeverity.high ||
                i.severity == DiagnosticSeverity.critical,
          )
            ? 'Fix recommended before relying on affected paths.'
            : 'You can work, with one or two paths quieter than usual.';

    final recommendation = _recommendationFrom(report);
    final created = report.createdAt.toLocal();
    final scannedAt =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} · '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    final duration = report.duration;
    final durationLabel = duration == null
        ? '—'
        : duration.inSeconds > 0
            ? '${duration.inSeconds}s'
            : '${duration.inMilliseconds}ms';

    return DashboardViewData(
      healthScore: report.health.score,
      healthLabel: healthLabel,
      healthDetail: healthDetail,
      healthTone: healthTone,
      confidenceLabel: HumanMessage.confidenceBadge(report.confidence),
      canStartWorking: canStartWorking,
      recommendationTitle: recommendation.title,
      recommendationDetail: recommendation.detail,
      recommendationTone: recommendation.tone,
      recommendationAction: recommendation.action,
      networkRows: _coreNetworkRowsFrom(meta),
      services: _servicesFrom(meta, report.issues, scannedAt),
      recentScan: RecentScanView(
        duration: durationLabel,
        issuesFound: report.issues.length,
        confidenceLabel: HumanMessage.confidenceBadge(report.confidence),
        scannedAt: scannedAt,
        tone: report.issues.isEmpty
            ? StatusBadgeTone.success
            : StatusBadgeTone.warning,
      ),
      technicalGroups: _technicalGroupsFrom(report, meta),
      scannedAtLabel: scannedAt,
    );
  }

  static ({
    String title,
    String detail,
    StatusBadgeTone tone,
    String? action,
  }) _recommendationFrom(DiagnosticReport report) {
    if (report.recommendations.isNotEmpty) {
      final rec = report.recommendations.first;
      return (
        title: rec.title,
        detail: rec.detail,
        tone: _toneForSeverity(rec.priority),
        action: rec.title,
      );
    }
    if (report.issues.isEmpty) {
      return (
        title: 'Everything looks healthy.',
        detail: 'No action required.',
        tone: StatusBadgeTone.success,
        action: null,
      );
    }
    return (
      title: 'No recommendation available.',
      detail: HumanMessage.fromProbeError(
        report.issues.first.description,
        fallback: report.issues.first.title,
      ),
      tone: StatusBadgeTone.neutral,
      action: null,
    );
  }

  /// Core network snapshot — DNS · IPv4 · IPv6 · TLS · HTTPS only.
  /// Never invents values; only maps collected diagnostics.
  static List<NetworkSnapshotRow> _coreNetworkRowsFrom(
    Map<String, String> meta,
  ) {
    final rows = <NetworkSnapshotRow>[];

    // DNS
    final dnsOk = meta['dns_success'] == 'true';
    final dnsMs = meta['dns_lookup_ms'];
    final dnsKnown = meta.containsKey('dns_success') || dnsMs != null;
    rows.add(
      NetworkSnapshotRow(
        title: 'DNS',
        summary: !dnsKnown
            ? '— Not Checked'
            : dnsOk
                ? (dnsMs != null ? '✓ $dnsMs ms' : '✓ Resolved')
                : '✕ Unavailable',
        explanation: !dnsKnown
            ? 'No DNS evidence in this scan.'
            : dnsOk
                ? 'Name lookup completed.'
                : HumanMessage.fromProbeError(
                    meta['dns_error'],
                    fallback: 'We couldn’t verify DNS.',
                  ),
        tone: !dnsKnown
            ? StatusBadgeTone.neutral
            : dnsOk
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        badge: !dnsKnown
            ? 'Not Checked'
            : dnsOk
                ? 'Healthy'
                : 'Unavailable',
        icon: Icons.dns_outlined,
      ),
    );

    // IPv4
    final ipv4Ok = meta['ipv4_success'] == 'true';
    final ipv4Ms = meta['ipv4_tcp_ms'] ?? meta['ipv4_latency_ms'];
    final ipv4Known = meta.containsKey('ipv4_success') || ipv4Ms != null;
    rows.add(
      NetworkSnapshotRow(
        title: 'IPv4',
        summary: !ipv4Known
            ? '— Not Checked'
            : ipv4Ok
                ? (ipv4Ms != null ? '✓ Connected · $ipv4Ms ms' : '✓ Connected')
                : '✕ Unavailable',
        explanation: !ipv4Known
            ? 'No IPv4 evidence in this scan.'
            : ipv4Ok
                ? 'TCP path connected.'
                : HumanMessage.fromProbeError(
                    meta['ipv4_error'],
                    fallback: 'We couldn’t verify IPv4.',
                  ),
        tone: !ipv4Known
            ? StatusBadgeTone.neutral
            : ipv4Ok
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        badge: !ipv4Known
            ? 'Not Checked'
            : ipv4Ok
                ? 'Connected'
                : 'Unavailable',
        icon: Icons.filter_1_rounded,
      ),
    );

    // IPv6
    final ipv6Ok = meta['ipv6_success'] == 'true';
    final ipv6Ms = meta['ipv6_tcp_ms'] ?? meta['ipv6_latency_ms'];
    final ipv6Error = meta['ipv6_error'] ?? '';
    final ipv6Known =
        meta.containsKey('ipv6_success') || ipv6Ms != null || ipv6Error.isNotEmpty;
    final noNative = ipv6Known &&
        !ipv6Ok &&
        (ipv6Error.toLowerCase().contains('no ipv6 address') ||
            ipv6Error.toLowerCase().contains('no ipv6 route') ||
            ipv6Error.toLowerCase().contains('no native'));
    rows.add(
      NetworkSnapshotRow(
        title: 'IPv6',
        summary: !ipv6Known
            ? '— Not Checked'
            : ipv6Ok
                ? (ipv6Ms != null ? '✓ Native · $ipv6Ms ms' : '✓ Native')
                : (noNative ? '— Ready' : '✕ Unavailable'),
        explanation: !ipv6Known
            ? 'No IPv6 evidence in this scan.'
            : ipv6Ok
                ? 'Native IPv6 path available.'
                : (noNative
                    ? 'No native IPv6 advertised.'
                    : HumanMessage.fromProbeError(
                        meta['ipv6_error'],
                        fallback: 'We couldn’t verify IPv6.',
                      )),
        tone: !ipv6Known
            ? StatusBadgeTone.neutral
            : ipv6Ok
                ? StatusBadgeTone.success
                : (noNative ? StatusBadgeTone.neutral : StatusBadgeTone.warning),
        badge: !ipv6Known
            ? 'Not Checked'
            : ipv6Ok
                ? 'Online'
                : (noNative ? 'Ready' : 'Unavailable'),
        icon: Icons.filter_6_rounded,
      ),
    );

    // TLS
    final cfOk = meta['cloudflare_success'] == 'true';
    final tlsMs = meta['cloudflare_tls_ms'];
    final tlsKnown = cfOk || tlsMs != null || meta['cloudflare_error'] != null;
    rows.add(
      NetworkSnapshotRow(
        title: 'TLS',
        summary: !tlsKnown
            ? '— Not Checked'
            : cfOk
                ? (tlsMs != null ? '✓ $tlsMs ms' : '✓ Successful')
                : '✕ Unavailable',
        explanation: !tlsKnown
            ? 'No TLS evidence in this scan.'
            : cfOk
                ? 'Secure handshake completed.'
                : HumanMessage.fromProbeError(
                    meta['cloudflare_error'],
                    fallback: 'TLS could not be verified.',
                  ),
        tone: !tlsKnown
            ? StatusBadgeTone.neutral
            : cfOk
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        badge: !tlsKnown
            ? 'Not Checked'
            : cfOk
                ? 'Healthy'
                : 'Unavailable',
        icon: Icons.lock_outline_rounded,
      ),
    );

    // HTTPS
    final cfStatus = meta['cloudflare_http_status'];
    final cfHttpMs = meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms'];
    final cfStatusCode = int.tryParse(cfStatus ?? '');
    final httpsKnown = meta.containsKey('cloudflare_success') ||
        cfStatus != null ||
        cfHttpMs != null;
    final httpsSummary = !httpsKnown
        ? '— Not Checked'
        : !cfOk
            ? '✕ Unavailable'
            : (cfStatusCode != null &&
                    cfStatusCode >= 200 &&
                    cfStatusCode < 400
                ? '✓ $cfStatusCode OK'
                : cfStatusCode != null
                    ? '✓ $cfStatusCode'
                    : (cfHttpMs != null ? '✓ $cfHttpMs ms' : '✓ Verified'));
    rows.add(
      NetworkSnapshotRow(
        title: 'HTTPS',
        summary: httpsSummary,
        explanation: !httpsKnown
            ? 'No HTTPS evidence in this scan.'
            : cfOk
                ? 'HTTPS verified successfully.'
                : HumanMessage.fromProbeError(
                    meta['cloudflare_error'],
                    fallback: 'We couldn’t verify HTTPS.',
                  ),
        tone: !httpsKnown
            ? StatusBadgeTone.neutral
            : cfOk
                ? StatusBadgeTone.success
                : StatusBadgeTone.error,
        badge: !httpsKnown
            ? 'Not Checked'
            : cfOk
                ? 'Healthy'
                : 'Unavailable',
        icon: Icons.https_outlined,
      ),
    );

    return rows;
  }

  static List<DeveloperServiceRow> _servicesFrom(
    Map<String, String> meta,
    List<DiagnosticIssue> issues,
    String scannedAt,
  ) {
    ServiceStatus statusFor({
      required bool known,
      required bool ok,
      required bool slow,
    }) {
      if (!known) return ServiceStatus.notChecked;
      if (slow) return ServiceStatus.slow;
      if (!ok) return ServiceStatus.unavailable;
      return ServiceStatus.healthy;
    }

    String? latencyLabel(String? ms) => ms == null ? null : '$ms ms';

    final ghKnown = meta.containsKey('github_success');
    final ghOk = meta['github_success'] == 'true';
    final ghSlow = issues.any(
      (i) => (i.code ?? i.id).toLowerCase().contains('github'),
    );

    final cfKnown = meta.containsKey('cloudflare_success');
    final cfOk = meta['cloudflare_success'] == 'true';

    final pypiProbed = meta.containsKey('pypi_index_http_ms') ||
        meta.containsKey('pypi_index_tcp_ms') ||
        meta.containsKey('pypi_files_http_ms');
    final pypiSlow = issues.any(
      (i) => (i.code ?? i.id).toLowerCase().contains('pypi'),
    );

    // Docker / AI APIs are not probed — Never invent Healthy/Slow.
    return [
      DeveloperServiceRow(
        name: 'GitHub',
        status: statusFor(known: ghKnown, ok: ghOk, slow: ghOk && ghSlow),
        icon: Icons.code_outlined,
        detail: ghKnown && ghOk
            ? latencyLabel(meta['github_http_ms'])
            : null,
        lastChecked: ghKnown ? scannedAt : null,
      ),
      DeveloperServiceRow(
        name: 'PyPI',
        status: statusFor(
          known: pypiProbed,
          ok: pypiProbed && !pypiSlow,
          slow: pypiSlow,
        ),
        icon: Icons.inventory_2_outlined,
        detail: pypiProbed ? latencyLabel(meta['pypi_index_http_ms']) : null,
        lastChecked: pypiProbed ? scannedAt : null,
      ),
      DeveloperServiceRow(
        name: 'Cloudflare',
        status: statusFor(known: cfKnown, ok: cfOk, slow: false),
        icon: Icons.cloud_outlined,
        detail: cfKnown && cfOk
            ? latencyLabel(
                meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms'],
              )
            : null,
        lastChecked: cfKnown ? scannedAt : null,
      ),
      const DeveloperServiceRow(
        name: 'Docker',
        status: ServiceStatus.notChecked,
        icon: Icons.widgets_outlined,
      ),
      const DeveloperServiceRow(
        name: 'AI APIs',
        status: ServiceStatus.notChecked,
        icon: Icons.auto_awesome_outlined,
      ),
    ];
  }

  static List<TechnicalGroupView> _technicalGroupsFrom(
    DiagnosticReport report,
    Map<String, String> meta,
  ) {
    final dns = <TechnicalLineView>[
      if (meta['dns_lookup_ms'] != null)
        TechnicalLineView(label: 'lookup', value: '${meta['dns_lookup_ms']} ms'),
      if (meta['dns_success'] != null)
        TechnicalLineView(label: 'success', value: meta['dns_success']!),
      if (meta['dns_error'] != null)
        TechnicalLineView(label: 'error', value: meta['dns_error']!),
    ];

    final tcp = <TechnicalLineView>[
      if (meta['ipv4_tcp_ms'] != null || meta['ipv4_latency_ms'] != null)
        TechnicalLineView(
          label: 'ipv4',
          value: '${meta['ipv4_tcp_ms'] ?? meta['ipv4_latency_ms']} ms',
        ),
      if (meta['ipv4_address'] != null)
        TechnicalLineView(label: 'ipv4_addr', value: meta['ipv4_address']!),
      if (meta['ipv4_error'] != null)
        TechnicalLineView(label: 'ipv4_error', value: meta['ipv4_error']!),
      if (meta['ipv6_tcp_ms'] != null || meta['ipv6_latency_ms'] != null)
        TechnicalLineView(
          label: 'ipv6',
          value: '${meta['ipv6_tcp_ms'] ?? meta['ipv6_latency_ms']} ms',
        ),
      if (meta['ipv6_address'] != null)
        TechnicalLineView(label: 'ipv6_addr', value: meta['ipv6_address']!),
      if (meta['ipv6_error'] != null)
        TechnicalLineView(label: 'ipv6_error', value: meta['ipv6_error']!),
    ];

    final tls = <TechnicalLineView>[
      if (meta['cloudflare_tls_ms'] != null)
        TechnicalLineView(
          label: 'handshake',
          value: '${meta['cloudflare_tls_ms']} ms',
        ),
      if (meta['github_tls_ms'] != null)
        TechnicalLineView(
          label: 'github',
          value: '${meta['github_tls_ms']} ms',
        ),
    ];

    final http = <TechnicalLineView>[
      if (meta['cloudflare_http_ms'] != null ||
          meta['cloudflare_latency_ms'] != null)
        TechnicalLineView(
          label: 'cloudflare',
          value:
              '${meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms']} ms',
        ),
      if (meta['cloudflare_http_status'] != null)
        TechnicalLineView(
          label: 'status',
          value: meta['cloudflare_http_status']!,
        ),
      if (meta['github_http_ms'] != null)
        TechnicalLineView(label: 'github', value: '${meta['github_http_ms']} ms'),
      if (meta['github_http_status'] != null)
        TechnicalLineView(
          label: 'github_status',
          value: meta['github_http_status']!,
        ),
      if (meta['pypi_index_http_ms'] != null)
        TechnicalLineView(
          label: 'pypi_index',
          value: '${meta['pypi_index_http_ms']} ms',
        ),
      if (meta['cloudflare_error'] != null)
        TechnicalLineView(label: 'error', value: meta['cloudflare_error']!),
      if (meta['github_error'] != null)
        TechnicalLineView(label: 'github_error', value: meta['github_error']!),
    ];

    final rules = <TechnicalLineView>[
      TechnicalLineView(
        label: 'evaluated',
        value: meta['rules_evaluated'] ?? '—',
      ),
      TechnicalLineView(
        label: 'failed',
        value: meta['rules_failed'] ?? '${report.issues.length}',
      ),
      for (final issue in report.issues)
        TechnicalLineView(
          label: issue.code ?? issue.id,
          value: issue.title,
        ),
    ];

    return [
      if (dns.isNotEmpty) TechnicalGroupView(title: 'DNS', lines: dns),
      if (tcp.isNotEmpty) TechnicalGroupView(title: 'TCP', lines: tcp),
      if (tls.isNotEmpty) TechnicalGroupView(title: 'TLS', lines: tls),
      if (http.isNotEmpty) TechnicalGroupView(title: 'HTTP', lines: http),
      TechnicalGroupView(title: 'Rules', lines: rules),
    ];
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
}

class NetworkSnapshotRow {
  const NetworkSnapshotRow({
    required this.title,
    required this.summary,
    required this.explanation,
    required this.tone,
    required this.badge,
    required this.icon,
  });

  final String title;

  /// Compact status line, e.g. `✓ Connected · 18 ms`.
  final String summary;
  final String explanation;
  final StatusBadgeTone tone;
  final String badge;
  final IconData icon;
}

enum ServiceStatus { healthy, slow, unavailable, notChecked }

class DeveloperServiceRow {
  const DeveloperServiceRow({
    required this.name,
    required this.status,
    required this.icon,
    this.detail,
    this.lastChecked,
  });

  final String name;
  final ServiceStatus status;
  final IconData icon;

  /// Latency when measured, never invented.
  final String? detail;

  /// Scan timestamp when this service was probed.
  final String? lastChecked;

  String get badgeLabel => switch (status) {
        ServiceStatus.healthy => 'Healthy',
        ServiceStatus.slow => 'Warning',
        ServiceStatus.unavailable => 'Unavailable',
        ServiceStatus.notChecked => 'Not Checked',
      };

  StatusBadgeTone get tone => switch (status) {
        ServiceStatus.healthy => StatusBadgeTone.success,
        ServiceStatus.slow => StatusBadgeTone.warning,
        ServiceStatus.unavailable => StatusBadgeTone.error,
        ServiceStatus.notChecked => StatusBadgeTone.neutral,
      };
}

class RecentScanView {
  const RecentScanView({
    required this.duration,
    required this.issuesFound,
    required this.confidenceLabel,
    required this.scannedAt,
    required this.tone,
  });

  final String duration;
  final int issuesFound;
  final String confidenceLabel;
  final String scannedAt;
  final StatusBadgeTone tone;
}

class TechnicalGroupView {
  const TechnicalGroupView({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<TechnicalLineView> lines;
}

class TechnicalLineView {
  const TechnicalLineView({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
