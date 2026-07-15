import 'package:flutter/material.dart';

enum DiagnosticOutcome {
  success,
  warning,
  info,
}

/// Presentation-only scan sequence — no mocked latency numbers.
class DiagnosticItemData {
  const DiagnosticItemData({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.activeVerb,
    required this.result,
    required this.icon,
    required this.outcome,
    required this.duration,
  });

  final String id;
  final String label;
  final String subtitle;

  /// Shown while this step is running — present-tense, no fake timings.
  final String activeVerb;

  /// Calm completion phrase — never mocked numbers.
  final String result;
  final IconData icon;
  final DiagnosticOutcome outcome;

  /// Animation pacing only — not a measured network latency.
  final Duration duration;
}

abstract final class DiagnosticsCatalog {
  static const List<DiagnosticItemData> items = [
    DiagnosticItemData(
      id: 'dns',
      label: 'DNS',
      subtitle: 'Name lookup',
      activeVerb: 'Resolving…',
      result: 'Resolved',
      icon: Icons.dns_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 720),
    ),
    DiagnosticItemData(
      id: 'ipv4',
      label: 'IPv4',
      subtitle: 'TCP path',
      activeVerb: 'Connecting…',
      result: 'Connected',
      icon: Icons.filter_1_rounded,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 640),
    ),
    DiagnosticItemData(
      id: 'ipv6',
      label: 'IPv6',
      subtitle: 'Native path',
      activeVerb: 'Connecting…',
      result: 'Checked',
      icon: Icons.filter_6_rounded,
      outcome: DiagnosticOutcome.info,
      duration: Duration(milliseconds: 880),
    ),
    DiagnosticItemData(
      id: 'tls',
      label: 'TLS',
      subtitle: 'Secure handshake',
      activeVerb: 'Negotiating TLS…',
      result: 'Handshake done',
      icon: Icons.lock_outline_rounded,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 700),
    ),
    DiagnosticItemData(
      id: 'https',
      label: 'HTTPS',
      subtitle: 'Secure request',
      activeVerb: 'Verifying HTTPS…',
      result: 'Verified',
      icon: Icons.https_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 640),
    ),
    DiagnosticItemData(
      id: 'github',
      label: 'GitHub',
      subtitle: 'api.github.com',
      activeVerb: 'Checking GitHub…',
      result: 'Checked',
      icon: Icons.code_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 900),
    ),
    DiagnosticItemData(
      id: 'pypi',
      label: 'PyPI',
      subtitle: 'pypi.org',
      activeVerb: 'Checking PyPI…',
      result: 'Checked',
      icon: Icons.inventory_2_outlined,
      outcome: DiagnosticOutcome.success,
      duration: Duration(milliseconds: 760),
    ),
  ];
}
