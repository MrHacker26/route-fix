import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';
import '../../../domain/autofix/shell_command_executor.dart';
import 'linux_dns_fix_operations.dart';
import 'linux_privileged_sysctl.dart';

/// Linux Auto Fix executor using privileged `sysctl` via `pkexec`.
final class LinuxPlatformFixExecutor implements PlatformFixExecutor {
  LinuxPlatformFixExecutor({
    required ShellCommandExecutor shell,
    LinuxPrivilegedSysctl? privileged,
    LinuxDnsFixOperations? dns,
  })  : _privileged = privileged ?? LinuxPrivilegedSysctl(shell: shell),
        _dns = dns ?? LinuxDnsFixOperations(shell: shell);

  final LinuxPrivilegedSysctl _privileged;
  final LinuxDnsFixOperations _dns;

  static const _preferSettings = <String>[
    'net.ipv6.conf.all.disable_ipv6=1',
    'net.ipv6.conf.default.disable_ipv6=1',
  ];

  static const _restoreSettings = <String>[
    'net.ipv6.conf.all.disable_ipv6=0',
    'net.ipv6.conf.default.disable_ipv6=0',
  ];

  @override
  FixPlatform get platform => FixPlatform.linux;

  @override
  bool supports(FixType type) =>
      type == FixType.preferIpv4 ||
      type == FixType.restoreDefault ||
      type == FixType.flushDnsCache ||
      type == FixType.changeDnsCloudflare ||
      type == FixType.restoreDns;

  @override
  Future<FixResult> apply(
    FixType type, {
    Map<String, String>? context,
  }) async {
    return switch (type) {
      FixType.preferIpv4 => _applySysctl(
          kind: FixActionKind.disableIpv6,
          settings: _preferSettings,
          successMessage: 'Prefer IPv4 is on.',
        ),
      FixType.restoreDefault => _applySysctl(
          kind: FixActionKind.enableIpv6,
          settings: _restoreSettings,
          successMessage: 'Defaults restored.',
        ),
      FixType.flushDnsCache => _dns.flushDns(platform),
      FixType.changeDnsCloudflare => _dns.applyCloudflare(platform),
      FixType.restoreDns => _dns.restoreDns(platform, context),
      _ => FixResult.notImplemented(
          type.toFixActionKind ?? FixActionKind.disableIpv6,
        ),
    };
  }

  Future<FixResult> _applySysctl({
    required FixActionKind kind,
    required List<String> settings,
    required String successMessage,
  }) async {
    for (final setting in settings) {
      if (!_isSafeSysctlAssignment(setting)) {
        throw const AutoFixValidationException(
          'Rejected unsafe sysctl assignment.',
        );
      }
    }

    final commands = [
      for (final setting in settings) 'sysctl -w $setting',
    ];

    late final LinuxPrivilegedCommandResult result;
    try {
      result = await _privileged.runSettings(settings);
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t update network settings.',
        error: error.message,
        executed: false,
        platform: platform,
        requiresElevation: true,
        metadata: {
          'commands': commands.join('; '),
          if (error.details != null) 'details': error.details!,
        },
      );
    }

    if (result.isCancelled) {
      return FixResult.cancelled(
        kind,
        platform: platform,
        executedCommand: result.executedCommand,
        metadata: {
          'commands': commands.join('; '),
          'shellCommand': result.shellCommand,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
          'exitCode': '${result.exitCode}',
        },
      );
    }

    if (result.outcome == LinuxPrivilegedOutcome.authFailed) {
      return FixResult.failure(
        kind,
        message: LinuxPrivilegedSysctl.authFailureMessage(result.stderr),
        error: result.stderr.isNotEmpty
            ? result.stderr
            : 'Administrator authentication failed.',
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {
          'commands': commands.join('; '),
          'shellCommand': result.shellCommand,
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          'exitCode': '${result.exitCode}',
          'outcome': 'AuthFailed',
        },
      );
    }

    if (!result.isSuccess) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t update network settings.',
        error: result.stderr.isNotEmpty
            ? result.stderr
            : (result.stdout.isNotEmpty
                ? result.stdout
                : 'exit code ${result.exitCode}'),
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {
          'commands': commands.join('; '),
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
        'commands': commands.join('; '),
        'shellCommand': result.shellCommand,
        'elevated': 'true',
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
      },
    );
  }

  static bool _isSafeSysctlAssignment(String setting) {
    return RegExp(
      r'^net\.ipv6\.conf\.(all|default)\.disable_ipv6=[01]$',
    ).hasMatch(setting);
  }
}
