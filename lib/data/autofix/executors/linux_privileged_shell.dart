import '../../../domain/autofix/shell_command_executor.dart';

/// Outcome of a privileged Linux shell invocation via `pkexec`.
enum LinuxPrivilegedShellOutcome {
  success,
  cancelled,
  authFailed,
  failed,
}

/// Structured result from a privileged Linux shell call.
final class LinuxPrivilegedShellResult {
  const LinuxPrivilegedShellResult({
    required this.outcome,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executedCommand,
    required this.shellCommand,
  });

  final LinuxPrivilegedShellOutcome outcome;
  final int exitCode;
  final String stdout;
  final String stderr;
  final String executedCommand;
  final String shellCommand;

  bool get isSuccess => outcome == LinuxPrivilegedShellOutcome.success;
  bool get isCancelled => outcome == LinuxPrivilegedShellOutcome.cancelled;
}

/// Runs validated DNS-related shell commands behind PolicyKit.
final class LinuxPrivilegedShell {
  const LinuxPrivilegedShell({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

  Future<LinuxPrivilegedShellResult> run(String shellCommand) async {
    if (!_isSafeShell(shellCommand)) {
      return LinuxPrivilegedShellResult(
        outcome: LinuxPrivilegedShellOutcome.failed,
        exitCode: 1,
        stdout: '',
        stderr: 'Rejected unsafe shell command.',
        executedCommand: 'pkexec sh -c <dns>',
        shellCommand: shellCommand,
      );
    }

    const executedCommand = 'pkexec sh -c <dns>';
    final result = await _shell.run('pkexec', ['sh', '-c', shellCommand]);
    return _mapResult(
      result: result,
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  LinuxPrivilegedShellResult _mapResult({
    required ShellCommandResult result,
    required String executedCommand,
    required String shellCommand,
  }) {
    final combined = '${result.stderr}\n${result.stdout}';

    if (result.isSuccess) {
      return LinuxPrivilegedShellResult(
        outcome: LinuxPrivilegedShellOutcome.success,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    if (_isUserCancelled(combined, result.exitCode)) {
      return LinuxPrivilegedShellResult(
        outcome: LinuxPrivilegedShellOutcome.cancelled,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    if (_isAuthFailure(combined, result.exitCode)) {
      return LinuxPrivilegedShellResult(
        outcome: LinuxPrivilegedShellOutcome.authFailed,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    return LinuxPrivilegedShellResult(
      outcome: LinuxPrivilegedShellOutcome.failed,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr.isNotEmpty ? result.stderr : combined.trim(),
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  static bool _isSafeShell(String shellCommand) {
    for (final segment in shellCommand.split('&&')) {
      final part = segment.trim();
      if (part.isEmpty) continue;
      if (_flushSegment.hasMatch(part)) continue;
      if (_resolvectlDnsSegment.hasMatch(part)) continue;
      if (_resolvectlRevertSegment.hasMatch(part)) continue;
      return false;
    }
    return shellCommand.trim().isNotEmpty;
  }

  static final _flushSegment = RegExp(
    r'^resolvectl flush-caches$',
  );

  static final _resolvectlDnsSegment = RegExp(
    r'^resolvectl dns [a-zA-Z0-9._-]+ '
    r'((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3})( '
    r'((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}))?$',
  );

  static final _resolvectlRevertSegment = RegExp(
    r'^resolvectl revert [a-zA-Z0-9._-]+$',
  );

  static bool _isUserCancelled(String text, int exitCode) {
    if (exitCode == 127) return true;
    final lower = text.toLowerCase();
    return lower.contains('dismissed') ||
        lower.contains('cancelled') ||
        lower.contains('canceled');
  }

  static bool _isAuthFailure(String text, int exitCode) {
    if (exitCode == 126) return true;
    final lower = text.toLowerCase();
    return lower.contains('authentication') ||
        lower.contains('not authorized') ||
        lower.contains('incorrect password');
  }

  static String authFailureMessage(String stderr) {
    if (stderr.toLowerCase().contains('incorrect password')) {
      return 'Password wasn’t accepted. Try again when prompted.';
    }
    return 'Admin access is required. Approve when prompted.';
  }
}
