import '../../../domain/autofix/shell_command_executor.dart';

/// Outcome of a privileged Linux sysctl invocation via `pkexec`.
enum LinuxPrivilegedOutcome {
  success,
  cancelled,
  authFailed,
  failed,
}

/// Structured result from a privileged Linux sysctl call.
final class LinuxPrivilegedCommandResult {
  const LinuxPrivilegedCommandResult({
    required this.outcome,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executedCommand,
    required this.shellCommand,
  });

  final LinuxPrivilegedOutcome outcome;
  final int exitCode;
  final String stdout;
  final String stderr;
  final String executedCommand;
  final String shellCommand;

  bool get isSuccess => outcome == LinuxPrivilegedOutcome.success;
  bool get isCancelled => outcome == LinuxPrivilegedOutcome.cancelled;
}

/// Runs validated `sysctl -w` assignments behind a PolicyKit prompt.
///
/// Uses one `pkexec sh -c '…'` invocation so the desktop shows a single
/// administrator password dialog per apply.
final class LinuxPrivilegedSysctl {
  const LinuxPrivilegedSysctl({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

  Future<LinuxPrivilegedCommandResult> runSettings(
    List<String> settings,
  ) async {
    if (settings.isEmpty) {
      return const LinuxPrivilegedCommandResult(
        outcome: LinuxPrivilegedOutcome.failed,
        exitCode: 1,
        stdout: '',
        stderr: 'No sysctl settings provided.',
        executedCommand: 'pkexec sh -c <sysctl>',
        shellCommand: '',
      );
    }

    for (final setting in settings) {
      if (!_isSafeSysctlAssignment(setting)) {
        return LinuxPrivilegedCommandResult(
          outcome: LinuxPrivilegedOutcome.failed,
          exitCode: 1,
          stdout: '',
          stderr: 'Rejected unsafe sysctl assignment: $setting',
          executedCommand: 'pkexec sh -c <sysctl>',
          shellCommand: '',
        );
      }
    }

    final shellCommand = settings
        .map((setting) => _posixCommand(['sysctl', '-w', setting]))
        .join(' && ');
    const executedCommand = 'pkexec sh -c <sysctl>';

    final result = await _shell.run('pkexec', ['sh', '-c', shellCommand]);
    return _mapResult(
      result: result,
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  LinuxPrivilegedCommandResult _mapResult({
    required ShellCommandResult result,
    required String executedCommand,
    required String shellCommand,
  }) {
    final combined = '${result.stderr}\n${result.stdout}';

    if (result.isSuccess) {
      return LinuxPrivilegedCommandResult(
        outcome: LinuxPrivilegedOutcome.success,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    if (_isUserCancelled(combined, result.exitCode)) {
      return LinuxPrivilegedCommandResult(
        outcome: LinuxPrivilegedOutcome.cancelled,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    if (_isAuthFailure(combined, result.exitCode)) {
      return LinuxPrivilegedCommandResult(
        outcome: LinuxPrivilegedOutcome.authFailed,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    return LinuxPrivilegedCommandResult(
      outcome: LinuxPrivilegedOutcome.failed,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr.isNotEmpty ? result.stderr : combined.trim(),
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  static bool _isUserCancelled(String text, int exitCode) {
    if (exitCode == 127) return true;
    final lower = text.toLowerCase();
    return lower.contains('dismissed') ||
        lower.contains('cancelled') ||
        lower.contains('canceled') ||
        lower.contains('not authorized to perform');
  }

  static bool _isAuthFailure(String text, int exitCode) {
    if (exitCode == 126) return true;
    final lower = text.toLowerCase();
    return lower.contains('authentication') ||
        lower.contains('not authorized') ||
        lower.contains('incorrect password') ||
        lower.contains('no such file or directory') && lower.contains('pkexec');
  }

  static String authFailureMessage(String stderr) {
    final lower = stderr.toLowerCase();
    if (lower.contains('pkexec') && lower.contains('no such file')) {
      return 'Admin tools are missing. Install polkit (pkexec) and try again.';
    }
    if (lower.contains('incorrect password')) {
      return 'Password wasn’t accepted. Try again when prompted.';
    }
    return 'Admin access is required. Approve when prompted.';
  }

  static bool _isSafeSysctlAssignment(String setting) {
    return RegExp(
      r'^net\.ipv6\.conf\.(all|default)\.disable_ipv6=[01]$',
    ).hasMatch(setting);
  }

  static String _posixCommand(List<String> argv) {
    return argv.map(_posixQuote).join(' ');
  }

  static String _posixQuote(String value) {
    if (RegExp(r'^[A-Za-z0-9_./:=+-]+$').hasMatch(value)) {
      return value;
    }
    return "'${value.replaceAll("'", r"'\''")}'";
  }
}
