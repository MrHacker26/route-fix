import 'diagnostic_severity.dart';

/// Suggested next step for the user after a diagnostic run.
///
/// Immutable value type — no behavior beyond data.
final class Recommendation {
  const Recommendation({
    required this.id,
    required this.title,
    required this.detail,
    this.priority = DiagnosticSeverity.info,
    this.actionLabel,
    this.relatedIssueIds = const [],
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String detail;
  final DiagnosticSeverity priority;

  /// Optional CTA label for UI (presentation-agnostic string).
  final String? actionLabel;

  /// Links this recommendation to one or more [DiagnosticIssue.id]s.
  final List<String> relatedIssueIds;

  /// Free-form extensible attributes.
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) {
    return other is Recommendation &&
        other.id == id &&
        other.title == title &&
        other.detail == detail &&
        other.priority == priority &&
        other.actionLabel == actionLabel &&
        _listEquals(other.relatedIssueIds, relatedIssueIds) &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        detail,
        priority,
        actionLabel,
        Object.hashAll(relatedIssueIds),
        Object.hashAll(
          metadata.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

bool _listEquals(List<String> a, List<String> b) {
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
