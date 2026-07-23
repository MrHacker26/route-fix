import 'dart:convert';

import '../../../domain/autofix/shell_command_executor.dart';

/// Outcome of a privileged Windows PowerShell invocation.
enum WindowsPrivilegedOutcome {
  success,
  cancelled,
  authFailed,
  failed,
}

/// Structured result from an elevated PowerShell call.
final class WindowsPrivilegedCommandResult {
  const WindowsPrivilegedCommandResult({
    required this.outcome,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executedCommand,
    required this.innerScript,
  });

  final WindowsPrivilegedOutcome outcome;
  final int exitCode;
  final String stdout;
  final String stderr;
  final String executedCommand;
  final String innerScript;

  bool get isSuccess => outcome == WindowsPrivilegedOutcome.success;
  bool get isCancelled => outcome == WindowsPrivilegedOutcome.cancelled;
}

/// Runs PowerShell behind a UAC elevation prompt.
///
/// Launches the inner script with:
/// `Start-Process powershell.exe -Verb RunAs -Wait -PassThru`
final class WindowsPrivilegedPowerShell {
  const WindowsPrivilegedPowerShell({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

  static const _cancelExitCode = 1220;

  Future<WindowsPrivilegedCommandResult> runScript(String script) async {
    if (script.trim().isEmpty) {
      return const WindowsPrivilegedCommandResult(
        outcome: WindowsPrivilegedOutcome.failed,
        exitCode: 1,
        stdout: '',
        stderr: 'No PowerShell script provided.',
        executedCommand: 'powershell.exe -Verb RunAs',
        innerScript: '',
      );
    }

    final encoded = base64Encode(utf8.encode(script));
    final outerCommand =
        "\$p = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru "
        "-ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-EncodedCommand','$encoded'; "
        'if (\$null -eq \$p) { exit $_cancelExitCode }; exit \$p.ExitCode';
    const executedCommand = 'powershell.exe -Verb RunAs';

    final result = await _shell.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      outerCommand,
    ]);

    return _mapResult(
      result: result,
      executedCommand: executedCommand,
      innerScript: script,
    );
  }

  WindowsPrivilegedCommandResult _mapResult({
    required ShellCommandResult result,
    required String executedCommand,
    required String innerScript,
  }) {
    final combined = '${result.stderr}\n${result.stdout}';

    if (result.isSuccess) {
      return WindowsPrivilegedCommandResult(
        outcome: WindowsPrivilegedOutcome.success,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        innerScript: innerScript,
      );
    }

    if (_isUserCancelled(combined, result.exitCode)) {
      return WindowsPrivilegedCommandResult(
        outcome: WindowsPrivilegedOutcome.cancelled,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        innerScript: innerScript,
      );
    }

    if (_isAuthFailure(combined)) {
      return WindowsPrivilegedCommandResult(
        outcome: WindowsPrivilegedOutcome.authFailed,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        innerScript: innerScript,
      );
    }

    return WindowsPrivilegedCommandResult(
      outcome: WindowsPrivilegedOutcome.failed,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr.isNotEmpty ? result.stderr : combined.trim(),
      executedCommand: executedCommand,
      innerScript: innerScript,
    );
  }

  static bool _isUserCancelled(String text, int exitCode) {
    if (exitCode == _cancelExitCode) return true;
    final lower = text.toLowerCase();
    return lower.contains('operation was canceled') ||
        lower.contains('operation was cancelled') ||
        lower.contains('the operation was canceled') ||
        lower.contains('user canceled') ||
        lower.contains('user cancelled');
  }

  static bool _isAuthFailure(String text) {
    final lower = text.toLowerCase();
    return lower.contains('access is denied') ||
        lower.contains('requires elevation') ||
        lower.contains('administrator');
  }

  static String authFailureMessage(String stderr) {
    final lower = stderr.toLowerCase();
    if (lower.contains('access is denied')) {
      return 'Admin access is required. Approve the UAC prompt to continue.';
    }
    return 'Admin access is required. Approve when prompted.';
  }
}
