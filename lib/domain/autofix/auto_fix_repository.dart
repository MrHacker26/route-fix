import 'models/applied_fix.dart';
import 'models/fix_type.dart';

/// Persists applied fixes so Restore Default can reverse them.
abstract interface class AutoFixRepository {
  Future<List<AppliedFix>> listApplied();

  Future<void> record(AppliedFix fix);

  Future<void> remove(String id);

  Future<void> clear();

  Future<bool> hasApplied(FixType type);
}
