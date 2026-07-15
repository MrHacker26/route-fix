import '../../../domain/autofix/auto_fix_repository.dart';
import '../../../domain/autofix/models/applied_fix.dart';
import '../../../domain/autofix/models/fix_type.dart';

/// Session-scoped applied-fix store (process lifetime).
final class InMemoryAutoFixRepository implements AutoFixRepository {
  final List<AppliedFix> _applied = [];

  @override
  Future<List<AppliedFix>> listApplied() async =>
      List<AppliedFix>.unmodifiable(_applied);

  @override
  Future<void> record(AppliedFix fix) async {
    _applied.removeWhere((item) => item.type == fix.type);
    _applied.add(fix);
  }

  @override
  Future<void> remove(String id) async {
    _applied.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clear() async {
    _applied.clear();
  }

  @override
  Future<bool> hasApplied(FixType type) async {
    return _applied.any((item) => item.type == type);
  }
}
