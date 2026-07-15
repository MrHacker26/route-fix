import 'models/fix_action.dart';
import 'models/fix_result.dart';

/// Contract for proposing and applying Auto Fix actions.
///
/// Implementations must not perform side effects unless explicitly executing
/// a supported fix (foundation providers never execute).
abstract interface class FixProvider {
  /// Platform this provider is bound to.
  FixPlatform get platform;

  /// Full catalog of actions with platform-specific availability.
  List<FixAction> availableActions();

  /// Whether [kind] can be applied by this provider (now or later).
  bool supports(FixActionKind kind);

  /// Apply [kind]. Foundation implementations must not mutate the system.
  Future<FixResult> apply(FixActionKind kind);
}
