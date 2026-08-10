import 'models/applied_fix.dart';
import 'models/fix_action.dart';
import 'models/fix_result.dart';
import 'models/fix_type.dart';
import 'platform_fix_executor.dart';

/// Application-facing Auto Fix orchestration.
///
/// Widgets call this — never [PlatformFixExecutor] or shell APIs directly.
abstract interface class AutoFixService {
  FixPlatform get platform;

  bool get isBusy;

  Stream<AutoFixPhase> get progress;

  List<AppliedFix> get appliedFixes;

  Future<FixResult> apply(
    FixType type, {
    void Function(AutoFixPhase phase)? onPhase,
    Map<String, String>? context,
  });

  /// Restores default network configuration for applied fixes.
  Future<FixResult> restoreDefault({
    void Function(AutoFixPhase phase)? onPhase,
  });

  bool supports(FixType type);
}
