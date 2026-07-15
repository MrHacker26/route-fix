import 'package:flutter/material.dart';

enum DiagnosticOutcome {
  success,
  warning,
  info,
}

/// Presentation-only diagnostic targets for the fake scan sequence.
class DiagnosticItemData {
  const DiagnosticItemData({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.result,
    required this.icon,
    required this.outcome,
    required this.duration,
  });

  final String id;
  final String label;
  final String subtitle;
  final String result;
  final IconData icon;
  final DiagnosticOutcome outcome;
  final Duration duration;
}

abstract final class DiagnosticsCatalog {
  static const List<DiagnosticItemData> items = [
    DiagnosticItemData(
      id: 'dns',
      label: 'DNS',
      subtitle: 'Resolver reachability',
      result: '24 ms · 1.1.1.1',
      icon: Icons.dns_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 720),
    ),
    DiagnosticItemData(
      id: 'ipv4',
      label: 'IPv4',
      subtitle: 'Default route check',
      result: 'Reachable · en0',
      icon: Icons.filter_1_rounded,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 640),
    ),
    DiagnosticItemData(
      id: 'ipv6',
      label: 'IPv6',
      subtitle: 'Dual-stack probe',
      result: 'No route advertised',
      icon: Icons.filter_6_rounded,
      outcome: DiagnosticOutcome.warning,
      duration: Duration(milliseconds: 880),
    ),
    DiagnosticItemData(
      id: 'github',
      label: 'GitHub',
      subtitle: 'api.github.com',
      result: '132 ms · elevated hop',
      icon: Icons.code_outlined,
      outcome: DiagnosticOutcome.warning,
      duration: Duration(milliseconds: 1100),
    ),
    DiagnosticItemData(
      id: 'cloudflare',
      label: 'Cloudflare',
      subtitle: 'Edge latency',
      result: '18 ms · healthy',
      icon: Icons.cloud_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 560),
    ),
    DiagnosticItemData(
      id: 'pypi',
      label: 'PyPI',
      subtitle: 'pypi.org',
      result: '41 ms · stable',
      icon: Icons.inventory_2_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 760),
    ),
  ];
}
