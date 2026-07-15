import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';
import '../../../domain/autofix/shell_command_executor.dart';

/// macOS Auto Fix executor using `networksetup` (argv only).
///
/// Prefer IPv4 → `networksetup -setv6off <service>`
/// Restore → `networksetup -setv6automatic <service>`
final class MacOsPlatformFixExecutor implements PlatformFixExecutor {
  MacOsPlatformFixExecutor({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

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
    final verb = enabled ? 'restore' : 'prefer IPv4 on';
    final flag = enabled ? '-setv6automatic' : '-setv6off';

    final services = await _resolveTargetServices(kind);
    if (services.isEmpty) {
      return FixResult.failure(
        kind,
        message: 'Could not $verb this network.',
        error: 'No enabled network services found.',
        executed: true,
        platform: platform,
        metadata: {'command': 'networksetup -listallnetworkservices'},
      );
    }

    final applied = <String>[];
    final skipped = <String>[];
    final commands = <String>[];
    final stdoutParts = <String>[];
    final stderrParts = <String>[];

    for (final service in services) {
      _validateServiceName(service);
      final args = [flag, service];
      commands.add('networksetup ${args.join(' ')}');

      late final ShellCommandResult result;
      try {
        result = await _shell.run('networksetup', args);
      } on AutoFixException catch (error) {
        return FixResult.failure(
          kind,
          message: 'Could not $verb this network.',
          error: error.message,
          executed: false,
          platform: platform,
          metadata: {
            'command': 'networksetup ${args.join(' ')}',
            if (error.details != null) 'details': error.details!,
          },
        );
      }

      if (result.stdout.isNotEmpty) stdoutParts.add(result.stdout);
      if (result.stderr.isNotEmpty) stderrParts.add(result.stderr);

      if (!result.isSuccess) {
        final detail = result.stderr.isNotEmpty
            ? result.stderr
            : (result.stdout.isNotEmpty
                ? result.stdout
                : 'exit code ${result.exitCode}');
        skipped.add('$service ($detail)');
        continue;
      }
      applied.add(service);
    }

    if (applied.isEmpty) {
      final errorText = skipped.isEmpty
          ? 'No network services were updated.'
          : skipped.join('; ');
      final permission = errorText.toLowerCase().contains('permission') ||
          errorText.toLowerCase().contains('not permitted');
      return FixResult.failure(
        kind,
        message: permission
            ? 'RouteFix needs administrator permission to continue.'
            : 'Could not $verb this network.',
        error: errorText,
        platform: platform,
        requiresElevation: permission,
        metadata: {
          'commands': commands.join('; '),
          'services': services.join(', '),
          if (stdoutParts.isNotEmpty) 'stdout': stdoutParts.join('\n'),
          if (stderrParts.isNotEmpty) 'stderr': stderrParts.join('\n'),
        },
      );
    }

    return FixResult.success(
      kind,
      message: enabled
          ? 'Network defaults restored (${applied.join(', ')}).'
          : 'Prefer IPv4 applied (${applied.join(', ')}).',
      platform: platform,
      metadata: {
        'commands': commands.join('; '),
        'applied': applied.join(', '),
        if (skipped.isNotEmpty) 'skipped': skipped.join('; '),
        'mode': enabled ? 'automatic' : 'off',
        if (stdoutParts.isNotEmpty) 'stdout': stdoutParts.join('\n'),
        if (stderrParts.isNotEmpty) 'stderr': stderrParts.join('\n'),
      },
    );
  }

  /// Active service when discoverable; otherwise all enabled services.
  Future<List<String>> _resolveTargetServices(FixActionKind kind) async {
    final all = await _listEnabledServices(kind);
    if (all.isEmpty) return const [];

    final active = await _detectActiveService(all);
    if (active != null) return [active];
    return all;
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

  Future<String?> _detectActiveService(List<String> services) async {
    String? iface;
    try {
      final route = await _shell.run('route', const ['-n', 'get', 'default']);
      if (route.isSuccess) {
        for (final line in route.stdout.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('interface:')) {
            iface = trimmed.substring('interface:'.length).trim();
            break;
          }
        }
      }
    } on AutoFixException {
      iface = null;
    }
    if (iface == null || iface.isEmpty) return null;

    try {
      final order = await _shell.run(
        'networksetup',
        const ['-listnetworkserviceorder'],
      );
      if (!order.isSuccess) return null;
      return _matchServiceForInterface(order.stdout, iface, services);
    } on AutoFixException {
      return null;
    }
  }

  /// Parses `networksetup -listnetworkserviceorder` against an interface.
  static String? _matchServiceForInterface(
    String stdout,
    String iface,
    List<String> enabled,
  ) {
    final normalizedIface = iface.toLowerCase();
    String? pendingService;
    for (final raw in stdout.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final serviceMatch = RegExp(r'^\(\d+\)\s+(.+)$').firstMatch(line);
      if (serviceMatch != null) {
        pendingService = serviceMatch.group(1)!.trim();
        continue;
      }
      if (pendingService != null &&
          line.toLowerCase().contains('device: $normalizedIface')) {
        if (enabled.contains(pendingService)) return pendingService;
      }
    }
    return null;
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
