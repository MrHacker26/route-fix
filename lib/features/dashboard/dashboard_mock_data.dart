import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Static presentation data for the dashboard. No networking.
abstract final class DashboardMockData {
  static const int healthScore = 78;
  static const String healthLabel = 'Good';
  static const String healthDetail =
      'Routing is mostly healthy. One service shows elevated latency.';

  static const ConnectionStatusMock connection = ConnectionStatusMock(
    title: 'Connected',
    subtitle: 'Ethernet · Local network reachable',
    tone: StatusBadgeTone.success,
    badgeLabel: 'Online',
    details: [
      ConnectionDetailMock(label: 'Interface', value: 'en0'),
      ConnectionDetailMock(label: 'Gateway', value: '192.168.1.1'),
      ConnectionDetailMock(label: 'DNS', value: '1.1.1.1'),
    ],
  );

  static const List<SummaryItemMock> summary = [
    SummaryItemMock(
      title: 'DNS resolution',
      detail: 'Resolving quickly across trusted resolvers',
      tone: StatusBadgeTone.success,
      badge: 'Healthy',
      icon: Icons.dns_outlined,
    ),
    SummaryItemMock(
      title: 'GitHub',
      detail: 'Round-trip delayed on the final hop',
      tone: StatusBadgeTone.warning,
      badge: 'Elevated',
      icon: Icons.code_outlined,
    ),
    SummaryItemMock(
      title: 'PyPI & Docker',
      detail: 'Stable paths with normal latency',
      tone: StatusBadgeTone.success,
      badge: 'Stable',
      icon: Icons.inventory_2_outlined,
    ),
  ];

  static const RecentScanMock recentScan = RecentScanMock(
    title: 'Evening diagnostic',
    timestamp: 'Today · 7:42 PM',
    duration: '18s',
    targets: 6,
    finding: 'GitHub latency +82ms vs baseline',
    tone: StatusBadgeTone.warning,
  );
}

class ConnectionStatusMock {
  const ConnectionStatusMock({
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
  final List<ConnectionDetailMock> details;
}

class ConnectionDetailMock {
  const ConnectionDetailMock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class SummaryItemMock {
  const SummaryItemMock({
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

class RecentScanMock {
  const RecentScanMock({
    required this.title,
    required this.timestamp,
    required this.duration,
    required this.targets,
    required this.finding,
    required this.tone,
  });

  final String title;
  final String timestamp;
  final String duration;
  final int targets;
  final String finding;
  final StatusBadgeTone tone;
}
