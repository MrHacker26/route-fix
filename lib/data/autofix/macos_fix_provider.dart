import 'dart:io';

import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import '../../domain/autofix/shell_command_executor.dart';
import 'executors/macos_platform_fix_executor.dart';
import 'shell/dart_io_shell_command_executor.dart';

/// Runs a host process for macOS Auto Fix adapters.
typedef MacOsFixProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// macOS Auto Fix adapter — delegates to [MacOsPlatformFixExecutor].
final class MacOsFixProvider extends PlatformFixProvider {
  MacOsFixProvider({
    MacOsFixProcessRunner? runProcess,
    ShellCommandExecutor? shell,
  }) : _executor = MacOsPlatformFixExecutor(
          shell: shell ??
              DartIoShellCommandExecutor(
                runProcess: runProcess,
              ),
        );

  final MacOsPlatformFixExecutor _executor;

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  Future<FixResult> applyStub(FixActionKind kind) {
    return _executor.apply(kind.toFixType);
  }
}
