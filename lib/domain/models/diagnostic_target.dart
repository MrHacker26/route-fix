/// A named probe target (DNS, GitHub, PyPI, etc.).
class DiagnosticTarget {
  const DiagnosticTarget({
    required this.id,
    required this.label,
    required this.hostHint,
    required this.kind,
  });

  final String id;
  final String label;
  final String hostHint;
  final DiagnosticTargetKind kind;
}

enum DiagnosticTargetKind {
  dns,
  ipv4,
  ipv6,
  httpService,
  api,
  registry,
}
