import '../../../domain/autofix/dns_presets.dart';
import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/shell_command_executor.dart';
import '../dns/dns_backup_codec.dart';
import 'macos_privileged_networksetup.dart';

/// macOS DNS flush / preset / restore via `networksetup` and cache tools.
final class MacOsDnsFixOperations {
  MacOsDnsFixOperations({
    required ShellCommandExecutor shell,
    MacOsPrivilegedNetworksetup? privileged,
  })  : _shell = shell,
        _privileged = privileged ?? MacOsPrivilegedNetworksetup(shell: shell);

  final ShellCommandExecutor _shell;
  final MacOsPrivilegedNetworksetup _privileged;

  Future<FixResult> flushDns(FixPlatform platform) async {
    const kind = FixActionKind.flushDns;
    const shellCommand =
        '/usr/bin/dscacheutil -flushcache && /usr/bin/killall -HUP mDNSResponder';

    late final MacOsPrivilegedCommandResult result;
    try {
      result = await _privileged.runPrivilegedShell(shellCommand);
    } on ArgumentError catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t flush DNS.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'command': shellCommand},
      );
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t flush DNS.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'command': shellCommand},
      );
    }

    return _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'flush',
      result: result,
      successMessage: 'DNS cache cleared.',
      commands: shellCommand,
    );
  }

  Future<FixResult> applyCloudflare(
    FixPlatform platform,
    Future<List<String>> Function() listServices,
  ) async {
    const kind = FixActionKind.changeDnsCloudflare;
    final services = await listServices();
    if (services.isEmpty) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t find a network service to update.',
        error: 'No enabled network services found.',
        executed: true,
        platform: platform,
      );
    }

    final backup = <String, List<String>>{};
    for (final service in services) {
      backup[service] = await _readDnsServers(service);
    }

    final segments = <String>[
      for (final service in services)
        _setDnsCommand(service, DnsPresets.cloudflare),
    ];
    final shellCommand = segments.join(' && ');

    late final MacOsPrivilegedCommandResult result;
    try {
      result = await _privileged.runPrivilegedShell(shellCommand);
    } on ArgumentError catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t update DNS.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'commands': shellCommand},
      );
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t update DNS.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'commands': shellCommand},
      );
    }

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
        'applied': services.join(', '),
        'preset': 'cloudflare',
      },
    );
  }

  Future<FixResult> restoreDns(
    FixPlatform platform,
    Map<String, String>? context,
    Future<List<String>> Function() listServices,
  ) async {
    const kind = FixActionKind.changeDnsCloudflare;
    var backup = DnsBackupCodec.decode(context?[DnsBackupCodec.metadataKey]);
    if (backup.isEmpty) {
      final services = await listServices();
      backup = {for (final service in services) service: <String>[]};
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
            ? _setDnsEmptyCommand(entry.key)
            : _setDnsCommand(entry.key, entry.value),
    ];
    final shellCommand = segments.join(' && ');

    late final MacOsPrivilegedCommandResult result;
    try {
      result = await _privileged.runPrivilegedShell(shellCommand);
    } on ArgumentError catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t restore DNS.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'commands': shellCommand},
      );
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t restore DNS.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'commands': shellCommand},
      );
    }

    return _mapPrivileged(
      kind: kind,
      platform: platform,
      verb: 'restore',
      result: result,
      successMessage: 'DNS restored.',
      commands: shellCommand,
    );
  }

  Future<List<String>> _readDnsServers(String service) async {
    late final ShellCommandResult result;
    try {
      result = await _shell.run('networksetup', ['-getdnsservers', service]);
    } on AutoFixException {
      return const [];
    }
    if (!result.isSuccess) return const [];
    final text = result.stdout.trim();
    if (text.contains('There aren\'t any DNS Servers')) {
      return const [];
    }
    return [
      for (final line in text.split('\n'))
        if (_isIpv4(line.trim())) line.trim(),
    ];
  }

  FixResult _mapPrivileged({
    required FixActionKind kind,
    required FixPlatform platform,
    required String verb,
    required MacOsPrivilegedCommandResult result,
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
          'shellCommand': result.shellCommand,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          'exitCode': '${result.exitCode}',
        },
      );
    }

    if (result.outcome == MacOsPrivilegedOutcome.authFailed) {
      return FixResult.failure(
        kind,
        message: MacOsPrivilegedNetworksetup.authFailureMessage(result.stderr),
        error: result.stderr.isNotEmpty
            ? result.stderr
            : 'Administrator authentication failed.',
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {
          'commands': commands,
          'shellCommand': result.shellCommand,
          'outcome': 'AuthFailed',
        },
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
          'commands': commands,
          'shellCommand': result.shellCommand,
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
        'shellCommand': result.shellCommand,
        'elevated': 'true',
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
      },
    );
  }

  static String _setDnsCommand(String service, List<String> servers) {
    _validateServiceName(service);
    for (final server in servers) {
      if (!_isIpv4(server)) {
        throw ArgumentError.value(server, 'server', 'Invalid DNS server.');
      }
    }
    final quoted = _quoteService(service);
    return 'networksetup -setdnsservers $quoted ${servers.join(' ')}';
  }

  static String _setDnsEmptyCommand(String service) {
    _validateServiceName(service);
    return 'networksetup -setdnsservers ${_quoteService(service)} Empty';
  }

  static String _quoteService(String service) {
    return "'${service.replaceAll("'", r"'\''")}'";
  }

  static void _validateServiceName(String service) {
    if (service.isEmpty ||
        service.contains('\n') ||
        service.contains('\r') ||
        service.contains('\u0000')) {
      throw ArgumentError.value(service, 'service', 'Invalid service name.');
    }
  }

  static bool _isIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }
}
