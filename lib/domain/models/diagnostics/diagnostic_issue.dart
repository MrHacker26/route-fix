import 'diagnostic_severity.dart';

/// A single detected routing or connectivity finding.
///
/// Immutable value type — no behavior beyond data.
final class DiagnosticIssue {
  const DiagnosticIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.code,
    this.target,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String description;
  final DiagnosticSeverity severity;

  /// Machine-readable issue code (extensible).
  final String? code;

  /// Optional host, check id, or surface this issue relates to.
  final String? target;

  /// Free-form extensible attributes.
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) {
    return other is DiagnosticIssue &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.severity == severity &&
        other.code == code &&
        other.target == target &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        severity,
        code,
        target,
        Object.hashAll(
          metadata.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
