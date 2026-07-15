import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import '../../domain/models/diagnostics/diagnostic_severity.dart';
import '../diagnostics/human_message.dart';

/// Presentation model for the dashboard — mapped from [DiagnosticReport].
final class DashboardViewData {
  const DashboardViewData({
    required this.healthScore,
    required this.healthLabel,
    required this.healthDetail,
    required this.healthTone,
    required this.connection,
    required this.summary,
    required this.recentScan,
    required this.confidence,
  });

  final int healthScore;
  final String healthLabel;
  final String healthDetail;
  final StatusBadgeTone healthTone;
  final ConnectionStatusView connection;
  final List<SummaryItemView> summary;
  final RecentScanView recentScan;
  final double confidence;

  factory DashboardViewData.fromReport(DiagnosticReport report) {
    final healthTone = _toneForScore(report.health.score);
    final meta = report.metadata;

    final ipv4Ok = meta['ipv4_success'] == 'true';
    final hostname = meta['target_hostname'] ?? 'network';
    final ipv4Address = meta['ipv4_address'] ?? '—';
    final ipv4TcpMs = meta['ipv4_tcp_ms'] ?? meta['ipv4_latency_ms'];
    final cloudflareStatus = meta['cloudflare_http_status'] ?? '—';
    final cloudflareHttpMs =
        meta['cloudflare_http_ms'] ?? meta['cloudflare_latency_ms'];

    final connection = ConnectionStatusView(
      title: ipv4Ok ? 'Connected' : 'Connection needs a look',
      subtitle: ipv4Ok
          ? 'Reachable · $hostname'
          : HumanMessage.fromProbeError(
              meta['ipv4_error'],
              fallback: 'Couldn’t confirm a clear IPv4 path',
            ),
      tone: ipv4Ok ? StatusBadgeTone.success : StatusBadgeTone.warning,
      badgeLabel: ipv4Ok ? 'Online' : 'Degraded',
      details: [
        ConnectionDetailView(label: 'Target', value: hostname),
        ConnectionDetailView(label: 'IPv4', value: ipv4Address),
        ConnectionDetailView(
          label: 'Edge status',
          value: cloudflareStatus,
        ),
      ],
    );

    final summary = <SummaryItemView>[];
    if (report.issues.isEmpty) {
      summary.addAll([
        const SummaryItemView(
          title: 'Routing',
          detail: 'No route problems showed up in this check',
          tone: StatusBadgeTone.success,
          badge: 'Healthy',
          icon: Icons.verified_outlined,
        ),
        SummaryItemView(
          title: 'Confidence',
          detail: '${(report.confidence * 100).round()}% sure about this reading',
          tone: StatusBadgeTone.info,
          badge: 'Stable',
          icon: Icons.insights_outlined,
        ),
        SummaryItemView(
          title: 'Internet path',
          detail: ipv4TcpMs == null
              ? 'Edge check completed'
              : 'IPv4 connect $ipv4TcpMs ms · HTTPS '
                  '${cloudflareHttpMs ?? cloudflareStatus}',
          tone: StatusBadgeTone.success,
          badge: 'OK',
          icon: Icons.cloud_outlined,
        ),
      ]);
    } else {
      for (final issue in report.issues.take(3)) {
        summary.add(
          SummaryItemView(
            title: issue.title,
            detail: HumanMessage.fromProbeError(
              issue.description,
              fallback: 'Something on this path needs attention',
            ),
            tone: _toneForSeverity(issue.severity),
            badge: HumanMessage.severityLabel(issue.severity.name),
            icon: _iconForIssue(issue.code ?? issue.id),
          ),
        );
      }
    }

    final finding = report.issues.isEmpty
        ? 'Looking calm · ${report.health.label}'
        : report.issues.first.title;

    final created = report.createdAt.toLocal();
    final timestamp =
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
      healthLabel: report.health.label,
      healthDetail: report.health.summary ??
          'Routing health based on the latest diagnostic run.',
      healthTone: healthTone,
      connection: connection,
      summary: summary,
      recentScan: RecentScanView(
        title: 'Diagnostic run',
        timestamp: timestamp,
        duration: durationLabel,
        targets: int.tryParse(meta['rules_evaluated'] ?? '') ?? 5,
        finding: finding,
        tone: report.issues.isEmpty
            ? StatusBadgeTone.success
            : StatusBadgeTone.warning,
        badgeLabel: report.issues.isEmpty ? 'Clear' : 'Needs review',
      ),
      confidence: report.confidence,
    );
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
    if (code.contains('ipv6')) return Icons.filter_6_rounded;
    if (code.contains('github')) return Icons.code_outlined;
    if (code.contains('pypi')) return Icons.inventory_2_outlined;
    return Icons.warning_amber_rounded;
  }
}

class ConnectionStatusView {
  const ConnectionStatusView({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.badgeLabel,
    required this.details,
  });

  final String title;
  final String subtitle;
  final StatusBadgeTone tone;
  final String badgeLabel;
  final List<ConnectionDetailView> details;
}

class ConnectionDetailView {
  const ConnectionDetailView({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class SummaryItemView {
  const SummaryItemView({
    required this.title,
    required this.detail,
    required this.tone,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String detail;
  final StatusBadgeTone tone;
  final String badge;
  final IconData icon;
}

class RecentScanView {
  const RecentScanView({
    required this.title,
    required this.timestamp,
    required this.duration,
    required this.targets,
    required this.finding,
    required this.tone,
    required this.badgeLabel,
  });

  final String title;
  final String timestamp;
  final String duration;
  final int targets;
  final String finding;
  final StatusBadgeTone tone;
  final String badgeLabel;
}
