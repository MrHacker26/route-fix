import 'dart:async';
import 'dart:io';

import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/shell_command_executor.dart';

/// Argv-based process runner shared by all PlatformFixExecutor adapters.
final class DartIoShellCommandExecutor implements ShellCommandExecutor {
  const DartIoShellCommandExecutor({
    this.runProcess,
  });

  /// Injectable for tests.
  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
  )? runProcess;

  static final _safeExecutable = RegExp(r'^[A-Za-z0-9_./\\:-]+$');

  @override
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async {
    final exe = executable.trim();
    if (exe.isEmpty || !_safeExecutable.hasMatch(exe)) {
      throw const AutoFixValidationException(
        'Rejected unsafe executable name.',
      );
    }
    for (final arg in arguments) {
      if (arg.contains('\u0000')) {
        throw const AutoFixValidationException(
          'Rejected argument containing a null byte.',
        );
      }
    }

    final runner = runProcess ??
        ((e, a) => Process.run(e, a, runInShell: false));

    try {
      final future = runner(exe, List<String>.unmodifiable(arguments));
      final result = timeout == null
          ? await future
          : await future.timeout(timeout);
      return ShellCommandResult(
        executable: exe,
        arguments: List<String>.unmodifiable(arguments),
        exitCode: result.exitCode,
        stdout: result.stdout.toString().trim(),
        stderr: result.stderr.toString().trim(),
      );
    } on TimeoutException {
      throw const AutoFixExecutionException(
        'The network change timed out.',
        details: 'Process timeout',
      );
    } on AutoFixException {
      rethrow;
    } on Object catch (error) {
      throw AutoFixExecutionException(
        'Could not run the network change.',
        details: error.toString(),
      );
    }
  }
}
