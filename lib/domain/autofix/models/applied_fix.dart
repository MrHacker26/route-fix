import 'fix_type.dart';

/// Record of a successfully applied Auto Fix (for restore / audit).
final class AppliedFix {
  const AppliedFix({
    required this.id,
    required this.type,
    required this.appliedAt,
    required this.platform,
    this.target = '',
    this.metadata = const {},
  });

  final String id;
  final FixType type;
  final DateTime appliedAt;
  final String platform;
  final String target;
  final Map<String, String> metadata;

  AppliedFix copyWith({
    String? id,
    FixType? type,
    DateTime? appliedAt,
    String? platform,
    String? target,
    Map<String, String>? metadata,
  }) {
    return AppliedFix(
      id: id ?? this.id,
      type: type ?? this.type,
      appliedAt: appliedAt ?? this.appliedAt,
      platform: platform ?? this.platform,
      target: target ?? this.target,
      metadata: metadata ?? this.metadata,
    );
  }
}
