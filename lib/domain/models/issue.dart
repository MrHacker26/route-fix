import 'health_score.dart';

/// A detected routing or connectivity issue.
class Issue {
  const Issue({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
    required this.tone,
  });

  final String id;
  final String title;
  final String detail;
  final IssueSeverity severity;
  final HealthTone tone;
}

enum IssueSeverity {
  low,
  medium,
  high,
}
