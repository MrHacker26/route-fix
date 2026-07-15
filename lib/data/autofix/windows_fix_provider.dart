import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/platform_fix_provider.dart';

/// Windows Auto Fix adapter — foundation stub (no system changes).
final class WindowsFixProvider extends PlatformFixProvider {
  const WindowsFixProvider();

  @override
  FixPlatform get platform => FixPlatform.windows;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return FixResult.notImplemented(kind);
  }
}
