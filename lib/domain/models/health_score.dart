/// Overall or category health score (0–100).
class HealthScore {
  const HealthScore({
    required this.value,
    required this.label,
    required this.summary,
  });

  final int value;
  final String label;
  final String summary;
}

/// Qualitative health tone for scores, checks, and connections.
enum HealthTone {
  healthy,
  degraded,
  failing,
  unknown,
}
