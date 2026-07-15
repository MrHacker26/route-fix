import 'diagnostic_issue.dart';
import 'network_health.dart';
import 'recommendation.dart';

/// Immutable aggregate output of a diagnostic run.
final class DiagnosticReport {
  const DiagnosticReport({
    required this.id,
    required this.createdAt,
    required this.health,
    this.issues = const [],
    this.recommendations = const [],
    this.duration,
    this.metadata = const {},
  });

  final String id;
  final DateTime createdAt;
  final NetworkHealth health;
  final List<DiagnosticIssue> issues;
  final List<Recommendation> recommendations;
  final Duration? duration;

  /// Free-form extensible attributes (app version, locale, etc.).
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) {
    return other is DiagnosticReport &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.health == health &&
        _listEquals(other.issues, issues) &&
        _listEquals(other.recommendations, recommendations) &&
        other.duration == duration &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        health,
        Object.hashAll(issues),
        Object.hashAll(recommendations),
        duration,
        Object.hashAll(
          metadata.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
