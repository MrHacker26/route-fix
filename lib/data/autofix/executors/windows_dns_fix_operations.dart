import '../../../domain/autofix/dns_presets.dart';
import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/shell_command_executor.dart';
import '../dns/dns_backup_codec.dart';
import 'windows_privileged_powershell.dart';

/// Windows DNS flush / preset / restore via elevated PowerShell.
final class WindowsDnsFixOperations {
  WindowsDnsFixOperations({
    required ShellCommandExecutor shell,
    WindowsPrivilegedPowerShell? privileged,
  })  : _shell = shell,
        _privileged = privileged ?? WindowsPrivilegedPowerShell(shell: shell);

  final ShellCommandExecutor _shell;
  final WindowsPrivilegedPowerShell _privileged;

  Future<FixResult> flushDns(FixPlatform platform) async {
    const kind = FixActionKind.flushDns;
    const script = 'Clear-DnsClientCache';
    final result = await _privileged.runScript(script);
    return _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'flush',
      result: result,
      successMessage: 'DNS cache cleared.',
      command: 'powershell.exe -Verb RunAs',
      innerScript: script,
    );
  }

  Future<FixResult> applyCloudflare(FixPlatform platform) async {
    const kind = FixActionKind.changeDnsCloudflare;
    final adapters = await _listActiveAdapters();
    if (adapters.isEmpty) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t find an active network adapter.',
        error: 'No up physical adapters found.',
        executed: true,
        platform: platform,
      );
    }

    final backup = <String, List<String>>{};
    for (final adapter in adapters) {
      backup[adapter] = await _readDnsServers(adapter);
    }

    final script = _buildSetDnsScript(
      adapters,
      DnsPresets.cloudflare,
    );
    final result = await _privileged.runScript(script);
    final mapped = _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'update',
      result: result,
      successMessage: 'Cloudflare DNS is on.',
      command: 'powershell.exe -Verb RunAs',
      innerScript: script,
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
        'applied': adapters.join(', '),
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
      final adapters = await _listActiveAdapters();
      backup = {for (final adapter in adapters) adapter: <String>[]};
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

    final script = _buildRestoreScript(backup);
    final result = await _privileged.runScript(script);
    return _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'restore',
      result: result,
      successMessage: 'DNS restored.',
      command: 'powershell.exe -Verb RunAs',
      innerScript: script,
    );
  }

  Future<List<String>> _listActiveAdapters() async {
    const script =
        r"Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | ForEach-Object { $_.Name }";
    late final ShellCommandResult result;
    try {
      result = await _shell.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
    } on AutoFixException {
      return const [];
    }
    if (!result.isSuccess) return const [];
    return [
      for (final line in result.stdout.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }

  Future<List<String>> _readDnsServers(String adapterName) async {
    final escaped = adapterName.replaceAll("'", "''");
    final script =
        "\$a = Get-NetAdapter -Name '$escaped' -ErrorAction SilentlyContinue; "
        'if (\$null -eq \$a) { exit 0 }; '
        '(Get-DnsClientServerAddress -InterfaceIndex \$a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join ","';
    late final ShellCommandResult result;
    try {
      result = await _shell.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
    } on AutoFixException {
      return const [];
    }
    if (!result.isSuccess) return const [];
    final text = result.stdout.trim();
    if (text.isEmpty) return const [];
    return [
      for (final part in text.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static String _buildSetDnsScript(
    List<String> adapters,
    List<String> servers,
  ) {
    final serverList = servers.map((s) => "'$s'").join(',');
    final buffer = StringBuffer();
    for (final adapter in adapters) {
      final escaped = adapter.replaceAll("'", "''");
      buffer.writeln(
        "\$a = Get-NetAdapter -Name '$escaped' -ErrorAction SilentlyContinue; "
        'if (\$null -ne \$a) { '
        'Set-DnsClientServerAddress -InterfaceIndex \$a.ifIndex '
        "-ServerAddresses @($serverList) -ErrorAction SilentlyContinue }",
      );
    }
    return buffer.toString().trim();
  }

  static String _buildRestoreScript(Map<String, List<String>> backup) {
    final buffer = StringBuffer();
    for (final entry in backup.entries) {
      final escaped = entry.key.replaceAll("'", "''");
      buffer.writeln(
        "\$a = Get-NetAdapter -Name '$escaped' -ErrorAction SilentlyContinue; "
        'if (\$null -ne \$a) { ',
      );
      if (entry.value.isEmpty) {
        buffer.writeln(
          'Set-DnsClientServerAddress -InterfaceIndex \$a.ifIndex '
          '-ResetServerAddresses -ErrorAction SilentlyContinue }',
        );
      } else {
        final serverList =
            entry.value.map((s) => "'${s.replaceAll("'", "''")}'").join(',');
        buffer.writeln(
          'Set-DnsClientServerAddress -InterfaceIndex \$a.ifIndex '
          "-ServerAddresses @($serverList) -ErrorAction SilentlyContinue }",
        );
      }
    }
    return buffer.toString().trim();
  }

  FixResult _mapPrivileged({
    required FixActionKind kind,
    required FixPlatform platform,
    required String verb,
    required WindowsPrivilegedCommandResult result,
    required String successMessage,
    required String command,
    required String innerScript,
  }) {
    if (result.isCancelled) {
      return FixResult.cancelled(
        kind,
        platform: platform,
        executedCommand: result.executedCommand,
        metadata: {
          'command': command,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          'exitCode': '${result.exitCode}',
        },
      );
    }

    if (result.outcome == WindowsPrivilegedOutcome.authFailed) {
      return FixResult.failure(
        kind,
        message: WindowsPrivilegedPowerShell.authFailureMessage(result.stderr),
        error: result.stderr.isNotEmpty
            ? result.stderr
            : 'Administrator authentication failed.',
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {'command': command, 'outcome': 'AuthFailed'},
      );
    }

    if (!result.isSuccess) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t $verb DNS settings.',
        error: result.stderr.isNotEmpty
            ? result.stderr
            : (result.stdout.isNotEmpty
                ? result.stdout
                : 'exit code ${result.exitCode}'),
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {
          'command': command,
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
        'command': command,
        'elevated': 'true',
        'innerScript': innerScript,
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
      },
    );
  }
}
