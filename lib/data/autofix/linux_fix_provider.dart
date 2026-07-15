import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/platform_fix_provider.dart';

/// Linux Auto Fix adapter — foundation stub (no system changes).
final class LinuxFixProvider extends PlatformFixProvider {
  const LinuxFixProvider();

  @override
  FixPlatform get platform => FixPlatform.linux;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return FixResult.notImplemented(kind);
  }
}
