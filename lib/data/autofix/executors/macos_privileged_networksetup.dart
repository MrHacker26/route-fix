import '../../../domain/autofix/shell_command_executor.dart';

/// Outcome of a privileged `networksetup` invocation via AppleScript.
enum MacOsPrivilegedOutcome {
  success,
  cancelled,
  authFailed,
  failed,
}

/// Structured result from a privileged macOS networksetup call.
final class MacOsPrivilegedCommandResult {
  const MacOsPrivilegedCommandResult({
    required this.outcome,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executedCommand,
    required this.shellCommand,
  });

  final MacOsPrivilegedOutcome outcome;
  final int exitCode;
  final String stdout;
  final String stderr;
  final String executedCommand;
  final String shellCommand;

  bool get isSuccess => outcome == MacOsPrivilegedOutcome.success;
  bool get isCancelled => outcome == MacOsPrivilegedOutcome.cancelled;
}

/// Runs `networksetup` behind macOS administrator authentication.
///
/// Uses a single:
/// `osascript -e 'do shell script "…" with administrator privileges'`
/// so the native password dialog appears once per apply.
final class MacOsPrivilegedNetworksetup {
  const MacOsPrivilegedNetworksetup({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

  /// Runs a validated shell script behind administrator authentication.
  Future<MacOsPrivilegedCommandResult> runPrivilegedShell(
    String shellCommand,
  ) async {
    _validatePrivilegedShell(shellCommand);
    if (shellCommand.trim().isEmpty) {
      return const MacOsPrivilegedCommandResult(
        outcome: MacOsPrivilegedOutcome.failed,
        exitCode: 1,
        stdout: '',
        stderr: 'No shell command provided.',
        executedCommand: 'osascript -e <privileged shell>',
        shellCommand: '',
      );
    }

    final appleScript =
        'do shell script ${_appleScriptString(shellCommand)} with administrator privileges';
    const executedCommand = 'osascript -e <privileged shell>';

    final result = await _shell.run('osascript', ['-e', appleScript]);
    return _mapResult(
      result: result,
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  /// Runs `networksetup <flag> <service>` for each service in one elevated script.
  Future<MacOsPrivilegedCommandResult> runForServices({
    required String flag,
    required List<String> services,
  }) async {
    _validateFlag(flag);
    if (services.isEmpty) {
      return const MacOsPrivilegedCommandResult(
        outcome: MacOsPrivilegedOutcome.failed,
        exitCode: 1,
        stdout: '',
        stderr: 'No network services provided.',
        executedCommand: 'osascript -e <privileged networksetup>',
        shellCommand: '',
      );
    }
    for (final service in services) {
      _validateServiceName(service);
    }

    final shellCommand = services
        .map(
          (service) => _posixCommand([
            'networksetup',
            flag,
            service,
          ]),
        )
        .join(' && ');
    final appleScript =
        'do shell script ${_appleScriptString(shellCommand)} with administrator privileges';
    const executedCommand = 'osascript -e <privileged networksetup>';

    final result = await _shell.run('osascript', ['-e', appleScript]);
    return _mapResult(
      result: result,
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  /// Convenience for a single service.
  Future<MacOsPrivilegedCommandResult> run({
    required String flag,
    required String service,
  }) {
    return runForServices(flag: flag, services: [service]);
  }

  MacOsPrivilegedCommandResult _mapResult({
    required ShellCommandResult result,
    required String executedCommand,
    required String shellCommand,
  }) {
    final combined = '${result.stderr}\n${result.stdout}';

    if (result.isSuccess) {
      return MacOsPrivilegedCommandResult(
        outcome: MacOsPrivilegedOutcome.success,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    if (_isUserCancelled(combined)) {
      return MacOsPrivilegedCommandResult(
        outcome: MacOsPrivilegedOutcome.cancelled,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    if (_isAuthFailure(combined)) {
      return MacOsPrivilegedCommandResult(
        outcome: MacOsPrivilegedOutcome.authFailed,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executedCommand: executedCommand,
        shellCommand: shellCommand,
      );
    }

    return MacOsPrivilegedCommandResult(
      outcome: MacOsPrivilegedOutcome.failed,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr.isNotEmpty ? result.stderr : combined.trim(),
      executedCommand: executedCommand,
      shellCommand: shellCommand,
    );
  }

  static bool _isUserCancelled(String text) {
    final lower = text.toLowerCase();
    return lower.contains('user canceled') ||
        lower.contains('user cancelled') ||
        lower.contains('(-128)') ||
        RegExp(r'(^|[^\d])-128([^\d]|$)').hasMatch(lower);
  }

  static bool _isAuthFailure(String text) {
    final lower = text.toLowerCase();
    return lower.contains('username or password was incorrect') ||
        lower.contains('authorization') ||
        lower.contains('authentication') ||
        lower.contains('not authorized') ||
        lower.contains('-60005') ||
        lower.contains('-60007') ||
        lower.contains('-60008');
  }

  /// Calm copy for auth dialog failures (not sandboxed denials).
  static String authFailureMessage(String stderr) {
    final lower = stderr.toLowerCase();
    if (lower.contains('username or password was incorrect') ||
        lower.contains('-60005')) {
      return 'Password wasn’t accepted. Try again when prompted.';
    }
    return 'Admin access is required. Approve when prompted.';
  }

  static void _validateFlag(String flag) {
    if (flag != '-setv6off' && flag != '-setv6automatic') {
      throw ArgumentError.value(flag, 'flag', 'Unsupported networksetup flag.');
    }
  }

  static final _flushDnsSegment = RegExp(
    r'^(/usr/bin/)?dscacheutil -flushcache$',
  );

  static final _setDnsSegment = RegExp(
    r"^networksetup -setdnsservers '([^'\\]|\\.)+' "
    r"((Empty)|"
    r"((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3})( "
    r"((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}))?)$",
  );

  static final _killMdnsSegment = RegExp(
    r'^(/usr/bin/)?killall -HUP mDNSResponder$',
  );

  static void _validatePrivilegedShell(String shellCommand) {
    for (final segment in shellCommand.split('&&')) {
      final part = segment.trim();
      if (part.isEmpty) continue;
      if (_flushDnsSegment.hasMatch(part)) continue;
      if (_killMdnsSegment.hasMatch(part)) continue;
      if (_setDnsSegment.hasMatch(part)) continue;
      throw ArgumentError.value(
        shellCommand,
        'shellCommand',
        'Rejected unsafe privileged shell segment: $part',
      );
    }
  }

  static void _validateServiceName(String service) {
    if (service.isEmpty ||
        service.contains('\n') ||
        service.contains('\r') ||
        service.contains('\u0000') ||
        service.contains("'") ||
        service.contains('"') ||
        service.contains('\\') ||
        service.contains('`') ||
        service.contains(r'$') ||
        service.contains(';') ||
        service.contains('|') ||
        service.contains('&') ||
        service.contains('>') ||
        service.contains('<')) {
      throw ArgumentError.value(
        service,
        'service',
        'Rejected unsafe network service name.',
      );
    }
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

  static String _appleScriptString(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
