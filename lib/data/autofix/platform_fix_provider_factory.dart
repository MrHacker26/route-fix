import 'dart:io';

import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/fix_provider_factory.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import 'linux_fix_provider.dart';
import 'macos_fix_provider.dart';
import 'windows_fix_provider.dart';

/// Builds a [PlatformFixProvider] for a given [FixPlatform].
typedef PlatformFixProviderBuilder = PlatformFixProvider Function();

/// Detects the host OS and returns the matching Auto Fix implementation.
///
/// The application should consume the returned value as [FixProvider] only.
/// This factory never executes fixes.
final class PlatformFixProviderFactory implements FixProviderFactory {
  const PlatformFixProviderFactory({
    this.platformOverride,
    this.providers = const {},
    this.fallback,
  });

  /// Forces a platform instead of reading [Platform] (tests / preview).
  final FixPlatform? platformOverride;

  /// Extra or replacement builders for current and future platforms.
  final Map<FixPlatform, PlatformFixProviderBuilder> providers;

  /// Used when the host is unsupported and no builder is registered.
  final PlatformFixProviderBuilder? fallback;

  /// Built-in Linux / macOS / Windows adapters.
  static final Map<FixPlatform, PlatformFixProviderBuilder> builtins = {
    FixPlatform.linux: LinuxFixProvider.new,
    FixPlatform.macOS: MacOsFixProvider.new,
    FixPlatform.windows: WindowsFixProvider.new,
  };

  /// Detects the current operating system.
  static FixPlatform detectHostPlatform() {
    if (Platform.isLinux) return FixPlatform.linux;
    if (Platform.isMacOS) return FixPlatform.macOS;
    if (Platform.isWindows) return FixPlatform.windows;
    return FixPlatform.unsupported;
  }

  @override
  FixProvider create() {
    final platform = platformOverride ?? detectHostPlatform();
    return createFor(platform);
  }

  @override
  PlatformFixProvider createFor(FixPlatform platform) {
    final custom = providers[platform];
    if (custom != null) return custom();

    final builtin = builtins[platform];
    if (builtin != null) return builtin();

    if (fallback != null) return fallback!();
    return const UnsupportedFixProvider();
  }
}

/// No-op adapter for hosts without an Auto Fix implementation yet.
final class UnsupportedFixProvider extends PlatformFixProvider {
  const UnsupportedFixProvider();

  @override
  FixPlatform get platform => FixPlatform.unsupported;

  @override
  List<FixAction> availableActions() => const [];

  @override
  bool supports(FixActionKind kind) => false;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return FixResult.unsupported(kind, platform);
  }
}

/// Application-facing convenience: [FixProvider] for the current host.
FixProvider createPlatformFixProvider({
  FixPlatform? platformOverride,
  Map<FixPlatform, PlatformFixProviderBuilder> providers = const {},
}) {
  return PlatformFixProviderFactory(
    platformOverride: platformOverride,
    providers: providers,
  ).create();
}
