import 'dart:io';

import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import 'linux_fix_provider.dart';
import 'macos_fix_provider.dart';
import 'windows_fix_provider.dart';

/// Resolves the correct [PlatformFixProvider] for the current host.
///
/// Selection only — no fixes are executed.
final class PlatformFixProviderFactory {
  const PlatformFixProviderFactory();

  PlatformFixProvider create() {
    if (Platform.isMacOS) return const MacOsFixProvider();
    if (Platform.isLinux) return const LinuxFixProvider();
    if (Platform.isWindows) return const WindowsFixProvider();
    return const _UnsupportedFixProvider();
  }
}

final class _UnsupportedFixProvider extends PlatformFixProvider {
  const _UnsupportedFixProvider();

  @override
  FixPlatform get platform => FixPlatform.linux;

  @override
  List<FixAction> availableActions() => const [];

  @override
  bool supports(FixActionKind kind) => false;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return FixResult.unsupported(kind, platform);
  }
}

/// Convenience binding as a [FixProvider].
FixProvider createPlatformFixProvider() {
  return const PlatformFixProviderFactory().create();
}
