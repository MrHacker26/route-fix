import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';
import '../../../domain/autofix/shell_command_executor.dart';
import 'macos_privileged_networksetup.dart';

/// macOS Auto Fix executor using privileged `networksetup` via AppleScript.
///
/// Prefer IPv4 → `networksetup -setv6off <service>` on each enabled service
/// Restore → `networksetup -setv6automatic <service>` on each enabled service
///
/// Mutations are elevated with:
/// `do shell script "…" with administrator privileges`
final class MacOsPlatformFixExecutor implements PlatformFixExecutor {
  MacOsPlatformFixExecutor({
    required ShellCommandExecutor shell,
    MacOsPrivilegedNetworksetup? privileged,
  })  : _shell = shell,
        _privileged = privileged ?? MacOsPrivilegedNetworksetup(shell: shell);

  final ShellCommandExecutor _shell;
  final MacOsPrivilegedNetworksetup _privileged;

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  bool supports(FixType type) =>
      type == FixType.preferIpv4 || type == FixType.restoreDefault;

  @override
  Future<FixResult> apply(FixType type) async {
    return switch (type) {
      FixType.preferIpv4 => _setIpv6(enabled: false),
      FixType.restoreDefault => _setIpv6(enabled: true),
      _ => FixResult.notImplemented(
          type.toFixActionKind ?? FixActionKind.disableIpv6,
        ),
    };
  }

  Future<FixResult> _setIpv6({required bool enabled}) async {
    final kind =
        enabled ? FixActionKind.enableIpv6 : FixActionKind.disableIpv6;
    final verb = enabled ? 'restore' : 'update';
    final flag = enabled ? '-setv6automatic' : '-setv6off';

    final services = await _resolveTargetServices(kind);
    if (services.isEmpty) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t find a network service to $verb.',
        error: 'No enabled network services found.',
        executed: true,
        platform: platform,
        metadata: {'command': 'networksetup -listallnetworkservices'},
      );
    }

    final applied = <String>[];
    final commands = <String>[
      for (final service in services) 'networksetup $flag $service',
    ];

    for (final service in services) {
      _validateServiceName(service);
    }

    late final MacOsPrivilegedCommandResult result;
    try {
      // One AppleScript → one native admin dialog for all services.
      result = await _privileged.runForServices(
        flag: flag,
        services: services,
      );
    } on ArgumentError catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t $verb network settings.',
        error: error.message,
        executed: false,
        platform: platform,
        metadata: {'commands': commands.join('; ')},
      );
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t $verb network settings.',
        error: error.message,
        executed: false,
        platform: platform,
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
        message: 'Couldn’t $verb network settings.',
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
          'services': services.join(', '),
          'shellCommand': result.shellCommand,
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          'exitCode': '${result.exitCode}',
        },
      );
    }

    applied.addAll(services);

    return FixResult.success(
      kind,
      message: enabled
          ? 'Defaults restored.'
          : 'Prefer IPv4 is on.',
      platform: platform,
      requiresElevation: true,
      executedCommand: result.executedCommand,
      metadata: {
        'commands': commands.join('; '),
        'applied': applied.join(', '),
        'mode': enabled ? 'automatic' : 'off',
        'shellCommand': result.shellCommand,
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
        'elevated': 'true',
      },
    );
  }

  /// All enabled network services — keeps IPv6 settings consistent for probes.
  Future<List<String>> _resolveTargetServices(FixActionKind kind) async {
    return _listEnabledServices(kind);
  }

  Future<List<String>> _listEnabledServices(FixActionKind kind) async {
    late final ShellCommandResult result;
    try {
      result = await _shell.run(
        'networksetup',
        const ['-listallnetworkservices'],
      );
    } on AutoFixException {
      return const [];
    }
    if (!result.isSuccess) return const [];
    return _parseNetworkServices(result.stdout);
  }

  static List<String> _parseNetworkServices(String stdout) {
    final services = <String>[];
    for (final rawLine in stdout.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().startsWith('an asterisk')) continue;
      if (line.startsWith('*')) continue;
      services.add(line);
    }
    return services;
  }

  static void _validateServiceName(String service) {
    if (service.isEmpty ||
        service.contains('\n') ||
        service.contains('\r') ||
        service.contains('\u0000')) {
      throw const AutoFixValidationException('Rejected invalid service name.');
    }
  }
}
