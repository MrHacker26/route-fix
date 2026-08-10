import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';

/// Friendly no-op executor for unsupported hosts.
final class UnsupportedPlatformFixExecutor implements PlatformFixExecutor {
  const UnsupportedPlatformFixExecutor();

  @override
  FixPlatform get platform => FixPlatform.unsupported;

  @override
  bool supports(FixType type) => false;

  @override
  Future<FixResult> apply(
    FixType type, {
    Map<String, String>? context,
  }) async {
    final kind = type.toFixActionKind ?? FixActionKind.disableIpv6;
    return FixResult.failure(
      kind,
      message: 'Auto Fix isn’t available here.',
      error: 'Unsupported platform.',
      executed: false,
      platform: platform,
    );
  }
}
