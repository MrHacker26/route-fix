import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Static presentation data for the diagnostics result screen.
abstract final class DiagnosticsResultMock {
  static const int overallScore = 74;
  static const String scoreLabel = 'Fair';
  static const String scoreSummary =
      'Most paths are healthy. GitHub latency and missing IPv6 are pulling the score down.';

  static const List<double> scoreBreakdown = [0.92, 0.88, 0.45, 0.61, 0.94, 0.86];
  static const List<String> breakdownLabels = [
    'DNS',
    'IPv4',
    'IPv6',
    'GitHub',
    'CF',
    'PyPI',
  ];

  static const List<double> latencyTrend = [
    28,
    31,
    27,
    42,
    38,
    55,
    49,
    68,
    72,
    61,
    58,
    64,
  ];

  static const List<LatencyBarMock> latencyBars = [
    LatencyBarMock(label: 'DNS', ms: 24, tone: StatusBadgeTone.success),
    LatencyBarMock(label: 'IPv4', ms: 18, tone: StatusBadgeTone.success),
    LatencyBarMock(label: 'GitHub', ms: 132, tone: StatusBadgeTone.warning),
    LatencyBarMock(label: 'Cloudflare', ms: 18, tone: StatusBadgeTone.success),
    LatencyBarMock(label: 'PyPI', ms: 41, tone: StatusBadgeTone.success),
  ];

  static const List<HealthCardMock> healthCards = [
    HealthCardMock(
      title: 'DNS',
      value: '24 ms',
      detail: 'Resolver healthy',
      tone: StatusBadgeTone.success,
      icon: Icons.dns_outlined,
      spark: [12, 14, 11, 15, 13, 12, 14, 13],
    ),
    HealthCardMock(
      title: 'IPv4',
      value: 'OK',
      detail: 'Default route up',
      tone: StatusBadgeTone.success,
      icon: Icons.filter_1_rounded,
      spark: [8, 9, 8, 7, 9, 8, 8, 7],
    ),
    HealthCardMock(
      title: 'IPv6',
      value: 'None',
      detail: 'No route found',
      tone: StatusBadgeTone.warning,
      icon: Icons.filter_6_rounded,
      spark: [2, 1, 0, 0, 1, 0, 0, 0],
    ),
    HealthCardMock(
      title: 'GitHub',
      value: '132 ms',
      detail: 'Elevated final hop',
      tone: StatusBadgeTone.warning,
      icon: Icons.code_outlined,
      spark: [44, 48, 52, 61, 78, 96, 118, 132],
    ),
    HealthCardMock(
      title: 'Cloudflare',
      value: '18 ms',
      detail: 'Edge path clean',
      tone: StatusBadgeTone.success,
      icon: Icons.cloud_outlined,
      spark: [16, 17, 15, 18, 16, 19, 17, 18],
    ),
    HealthCardMock(
      title: 'PyPI',
      value: '41 ms',
      detail: 'Stable index path',
      tone: StatusBadgeTone.success,
      icon: Icons.inventory_2_outlined,
      spark: [36, 38, 40, 39, 42, 41, 40, 41],
    ),
  ];

  static const List<IssueMock> issues = [
    IssueMock(
      title: 'GitHub latency elevated',
      detail:
          'Round-trip to api.github.com is ~82 ms above your recent baseline on the final hop.',
      severity: 'Medium',
      tone: StatusBadgeTone.warning,
      icon: Icons.south_east_rounded,
    ),
    IssueMock(
      title: 'IPv6 unavailable',
      detail:
          'No IPv6 route is advertised on this interface. Dual-stack services fall back to IPv4.',
      severity: 'Low',
      tone: StatusBadgeTone.info,
      icon: Icons.link_off_rounded,
    ),
  ];

  static const List<RecommendationMock> recommendations = [
    RecommendationMock(
      title: 'Warm the GitHub path',
      detail:
          'Retry during off-peak, or pin a nearby mirror if your workflows hammer the API.',
      icon: Icons.bolt_outlined,
    ),
    RecommendationMock(
      title: 'Confirm ISP IPv6',
      detail:
          'If you expect dual-stack, check router WAN settings — this scan only observed IPv4.',
      icon: Icons.settings_ethernet_rounded,
    ),
    RecommendationMock(
      title: 'Keep DNS locked',
      detail:
          '1.1.1.1 stayed fast. No change needed unless corporate DNS must be forced.',
      icon: Icons.verified_outlined,
    ),
  ];
}

class LatencyBarMock {
  const LatencyBarMock({
    required this.label,
    required this.ms,
    required this.tone,
  });

  final String label;
  final double ms;
  final StatusBadgeTone tone;
}

class HealthCardMock {
  const HealthCardMock({
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

class IssueMock {
  const IssueMock({
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

class RecommendationMock {
  const RecommendationMock({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}
