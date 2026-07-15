import 'dart:io';

import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import '../../domain/autofix/shell_command_executor.dart';
import 'executors/linux_platform_fix_executor.dart';
import 'shell/dart_io_shell_command_executor.dart';

/// Runs a host process for Linux Auto Fix adapters.
typedef LinuxFixProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Linux Auto Fix adapter — delegates to [LinuxPlatformFixExecutor].
final class LinuxFixProvider extends PlatformFixProvider {
  LinuxFixProvider({
    LinuxFixProcessRunner? runProcess,
    ShellCommandExecutor? shell,
  }) : _executor = LinuxPlatformFixExecutor(
          shell: shell ??
              DartIoShellCommandExecutor(
                runProcess: runProcess,
              ),
        );

  final LinuxPlatformFixExecutor _executor;

  @override
  FixPlatform get platform => FixPlatform.linux;

  @override
  Future<FixResult> applyStub(FixActionKind kind) {
    return _executor.apply(kind.toFixType);
  }
}
