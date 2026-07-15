import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/platform_fix_provider.dart';

/// macOS Auto Fix adapter — foundation stub (no system changes).
final class MacOsFixProvider extends PlatformFixProvider {
  const MacOsFixProvider();

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return FixResult.notImplemented(kind);
  }
}
