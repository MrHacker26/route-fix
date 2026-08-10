import '../../../domain/autofix/dns_presets.dart';
import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/shell_command_executor.dart';
import '../dns/dns_backup_codec.dart';
import 'linux_privileged_shell.dart';

/// Linux DNS flush / preset / restore via `resolvectl`.
final class LinuxDnsFixOperations {
  LinuxDnsFixOperations({
    required ShellCommandExecutor shell,
    LinuxPrivilegedShell? privileged,
  })  : _shell = shell,
        _privileged = privileged ?? LinuxPrivilegedShell(shell: shell);

  final ShellCommandExecutor _shell;
  final LinuxPrivilegedShell _privileged;

  Future<FixResult> flushDns(FixPlatform platform) async {
    const kind = FixActionKind.flushDns;
    const shellCommand = 'resolvectl flush-caches';
    final result = await _privileged.run(shellCommand);
    return _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'flush',
      result: result,
      successMessage: 'DNS cache cleared.',
      commands: shellCommand,
    );
  }

  Future<FixResult> applyCloudflare(FixPlatform platform) async {
    const kind = FixActionKind.changeDnsCloudflare;
    final link = await _defaultLink();
    if (link == null) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t find an active network interface.',
        error: 'No default route interface found.',
        executed: true,
        platform: platform,
      );
    }

    final current = await _readDnsServers(link);
    final backup = {link: current};
    final shellCommand =
        'resolvectl dns $link ${DnsPresets.cloudflare.join(' ')}';
    final result = await _privileged.run(shellCommand);
    final mapped = _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'update',
      result: result,
      successMessage: 'Cloudflare DNS is on.',
      commands: shellCommand,
    );
    if (!mapped.success) return mapped;

    return FixResult.success(
      kind,
      message: mapped.message ?? 'Cloudflare DNS is on.',
      platform: platform,
      requiresElevation: true,
      executedCommand: mapped.executedCommand,
      metadata: {
        ...mapped.metadata,
        DnsBackupCodec.metadataKey: DnsBackupCodec.encode(backup),
        'applied': link,
        'preset': 'cloudflare',
      },
    );
  }

  Future<FixResult> restoreDns(
    FixPlatform platform,
    Map<String, String>? context,
  ) async {
    const kind = FixActionKind.changeDnsCloudflare;
    var backup = DnsBackupCodec.decode(context?[DnsBackupCodec.metadataKey]);
    if (backup.isEmpty) {
      final link = await _defaultLink();
      if (link != null) {
        backup = {link: const []};
      }
    }
    if (backup.isEmpty) {
      return FixResult(
        action: kind,
        success: true,
        executed: false,
        message: 'Nothing to restore for DNS.',
        platform: platform,
      );
    }

    final segments = <String>[
      for (final entry in backup.entries)
        entry.value.isEmpty
            ? 'resolvectl revert ${entry.key}'
            : 'resolvectl dns ${entry.key} ${entry.value.join(' ')}',
    ];
    final shellCommand = segments.join(' && ');
    final result = await _privileged.run(shellCommand);
    return _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'restore',
      result: result,
      successMessage: 'DNS restored.',
      commands: shellCommand,
    );
  }

  Future<String?> _defaultLink() async {
    late final ShellCommandResult result;
    try {
      result = await _shell.run('ip', ['-4', 'route', 'show', 'default']);
    } on AutoFixException {
      return null;
    }
    if (!result.isSuccess) return null;
    for (final line in result.stdout.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5 && parts.first == 'default') {
        return parts[4];
      }
    }
    return null;
  }

  Future<List<String>> _readDnsServers(String link) async {
    late final ShellCommandResult result;
    try {
      result = await _shell.run('resolvectl', ['dns', link]);
    } on AutoFixException {
      return const [];
    }
    if (!result.isSuccess) return const [];
    return [
      for (final match
          in RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b').allMatches(result.stdout))
        match.group(0)!,
    ];
  }

  FixResult _mapPrivileged({
    required FixActionKind kind,
    required FixPlatform platform,
    required String verb,
    required LinuxPrivilegedShellResult result,
    required String successMessage,
    required String commands,
  }) {
    if (result.isCancelled) {
      return FixResult.cancelled(
        kind,
        platform: platform,
        executedCommand: result.executedCommand,
        metadata: {
          'commands': commands,
          'exitCode': '${result.exitCode}',
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
        },
      );
    }

    if (result.outcome == LinuxPrivilegedShellOutcome.authFailed) {
      return FixResult.failure(
        kind,
        message: LinuxPrivilegedShell.authFailureMessage(result.stderr),
        error: result.stderr.isNotEmpty
            ? result.stderr
            : 'Administrator authentication failed.',
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {'commands': commands, 'outcome': 'AuthFailed'},
      );
    }

    if (!result.isSuccess) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t $verb DNS settings.',
        error: result.stderr.isNotEmpty
            ? result.stderr
            : 'exit code ${result.exitCode}',
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {
          'commands': commands,
          'exitCode': '${result.exitCode}',
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
        },
      );
    }

    return FixResult.success(
      kind,
      message: successMessage,
      platform: platform,
      requiresElevation: true,
      executedCommand: result.executedCommand,
      metadata: {
        'commands': commands,
        'elevated': 'true',
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
      },
    );
  }
}
