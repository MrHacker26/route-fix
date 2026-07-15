import 'models/fix_result.dart';
import 'models/fix_type.dart';
import 'models/fix_action.dart';

/// Progress phases emitted while a fix is applying.
enum AutoFixPhase {
  applying,
  updatingNetwork,
  restartingInterface,
  verifying,
  restoring,
}

extension AutoFixPhaseLabel on AutoFixPhase {
  String get label => switch (this) {
        AutoFixPhase.applying => 'Applying fix…',
        AutoFixPhase.updatingNetwork => 'Updating network…',
        AutoFixPhase.restartingInterface => 'Restarting interface…',
        AutoFixPhase.verifying => 'Verifying…',
        AutoFixPhase.restoring => 'Restoring defaults…',
      };
}

/// Platform-isolated executor for network Auto Fixes.
abstract interface class PlatformFixExecutor {
  FixPlatform get platform;

  /// Whether [type] can be attempted on this host.
  bool supports(FixType type);

  /// Apply [type]. Must not invent success without real execution evidence.
  Future<FixResult> apply(FixType type);
}
