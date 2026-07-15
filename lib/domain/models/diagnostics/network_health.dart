/// Snapshot of overall network routing health.
///
/// Immutable value type — score is 0–100; [metrics] is extensible.
final class NetworkHealth {
  const NetworkHealth({
    required this.score,
    required this.label,
    this.summary,
    this.checkedAt,
    this.metrics = const {},
  });

  /// Health score in the inclusive range 0–100.
  final int score;

  /// Short human label (e.g. Good, Fair, Poor).
  final String label;

  final String? summary;
  final DateTime? checkedAt;

  /// Named numeric metrics (latency ms, loss %, etc.) for extension.
  final Map<String, double> metrics;

  @override
  bool operator ==(Object other) {
    return other is NetworkHealth &&
        other.score == score &&
        other.label == label &&
        other.summary == summary &&
        other.checkedAt == checkedAt &&
        _mapEquals(other.metrics, metrics);
  }

  @override
  int get hashCode => Object.hash(
        score,
        label,
        summary,
        checkedAt,
        Object.hashAll(
          metrics.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

bool _mapEquals(Map<String, double> a, Map<String, double> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
