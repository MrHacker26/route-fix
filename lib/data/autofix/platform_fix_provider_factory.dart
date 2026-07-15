import 'dart:io';

import '../../domain/autofix/auto_fix_repository.dart';
import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/fix_provider_factory.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_executor.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import '../../domain/autofix/shell_command_executor.dart';
import 'executors/linux_platform_fix_executor.dart';
import 'executors/macos_platform_fix_executor.dart';
import 'executors/unsupported_platform_fix_executor.dart';
import 'executors/windows_platform_fix_executor.dart';
import 'linux_fix_provider.dart';
import 'macos_fix_provider.dart';
import 'repository/in_memory_auto_fix_repository.dart';
import 'service/default_auto_fix_service.dart';
import 'shell/dart_io_shell_command_executor.dart';
import 'windows_fix_provider.dart';

/// Builds a [PlatformFixProvider] for a given [FixPlatform].
typedef PlatformFixProviderBuilder = PlatformFixProvider Function();

/// Detects the host OS and returns Auto Fix adapters / services.
///
/// Prefer [createService] for new code. [create] remains the [FixProvider]
/// catalog bridge used by recommendation UI.
final class PlatformFixProviderFactory implements FixProviderFactory {
  const PlatformFixProviderFactory({
    this.platformOverride,
    this.providers = const {},
    this.fallback,
    this.shell,
    this.repository,
  });

  /// Forces a platform instead of reading [Platform] (tests / preview).
  final FixPlatform? platformOverride;

  /// Extra or replacement builders for current and future platforms.
  final Map<FixPlatform, PlatformFixProviderBuilder> providers;

  /// Used when the host is unsupported and no builder is registered.
  final PlatformFixProviderBuilder? fallback;

  final ShellCommandExecutor? shell;
  final AutoFixRepository? repository;

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

  PlatformFixExecutor createExecutor([FixPlatform? platform]) {
    final resolved = platform ?? platformOverride ?? detectHostPlatform();
    final shellExecutor = shell ?? const DartIoShellCommandExecutor();
    return switch (resolved) {
      FixPlatform.macOS => MacOsPlatformFixExecutor(shell: shellExecutor),
      FixPlatform.linux => LinuxPlatformFixExecutor(shell: shellExecutor),
      FixPlatform.windows => WindowsPlatformFixExecutor(shell: shellExecutor),
      FixPlatform.unsupported => const UnsupportedPlatformFixExecutor(),
    };
  }

  AutoFixService createService([FixPlatform? platform]) {
    return DefaultAutoFixService(
      executor: createExecutor(platform),
      repository: repository ?? InMemoryAutoFixRepository(),
    );
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

/// Application-facing convenience: [AutoFixService] for the current host.
AutoFixService createAutoFixService({
  FixPlatform? platformOverride,
  ShellCommandExecutor? shell,
  AutoFixRepository? repository,
}) {
  return PlatformFixProviderFactory(
    platformOverride: platformOverride,
    shell: shell,
    repository: repository,
  ).createService();
}
