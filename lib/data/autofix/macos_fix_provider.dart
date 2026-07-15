import 'dart:io';

import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_provider.dart';

/// Runs a host process for macOS Auto Fix adapters.
typedef MacOsFixProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// macOS Auto Fix adapter.
///
/// Implements IPv6 toggle via `networksetup`.
final class MacOsFixProvider extends PlatformFixProvider {
  const MacOsFixProvider({
    this._runProcess,
  });

  final MacOsFixProcessRunner? _runProcess;

  MacOsFixProcessRunner get _runner =>
      _runProcess ??
      ((executable, arguments) => Process.run(executable, arguments));

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return switch (kind) {
      FixActionKind.disableIpv6 => _setIpv6(enabled: false),
      FixActionKind.enableIpv6 => _setIpv6(enabled: true),
      FixActionKind.flushDns || FixActionKind.openWarp =>
        FixResult.notImplemented(kind),
    };
  }

  /// Applies IPv6 off/automatic to every enabled network service.
  ///
  /// Disable: `networksetup -setv6off <service>`
  /// Enable:  `networksetup -setv6automatic <service>`
  Future<FixResult> _setIpv6({required bool enabled}) async {
    final kind =
        enabled ? FixActionKind.enableIpv6 : FixActionKind.disableIpv6;
    final verb = enabled ? 'enable' : 'disable';
    final flag = enabled ? '-setv6automatic' : '-setv6off';

    final servicesResult = await _listNetworkServices(kind, verb);
    if (servicesResult.$1 != null) {
      return servicesResult.$1!;
    }
    final services = servicesResult.$2!;

    if (services.isEmpty) {
      return FixResult.failure(
        kind,
        message: 'Failed to $verb IPv6.',
        error: 'No enabled network services found.',
        executed: true,
        metadata: {'command': 'networksetup -listallnetworkservices'},
      );
    }

    final applied = <String>[];
    final skipped = <String>[];
    final commands = <String>[];

    for (final service in services) {
      final command = 'networksetup $flag $service';
      commands.add(command);

      late final ProcessResult result;
      try {
        result = await _runner('networksetup', [flag, service]);
      } on Object catch (error) {
        return FixResult.failure(
          kind,
          message: 'Failed to $verb IPv6.',
          error: error.toString(),
          executed: false,
          metadata: {
            'command': command,
            'services': services.join(', '),
          },
        );
      }

      final stderr = _asTrimmedString(result.stderr);
      final stdout = _asTrimmedString(result.stdout);

      if (result.exitCode != 0) {
        final detail = stderr.isNotEmpty
            ? stderr
            : (stdout.isNotEmpty ? stdout : 'exit code ${result.exitCode}');
        skipped.add('$service ($detail)');
        continue;
      }

      applied.add(service);
    }

    if (applied.isEmpty) {
      return FixResult.failure(
        kind,
        message: 'Failed to $verb IPv6.',
        error: skipped.isEmpty
            ? 'No network services were updated.'
            : skipped.join('; '),
        metadata: {
          'commands': commands.join('; '),
          'services': services.join(', '),
        },
      );
    }

    return FixResult.success(
      kind,
      message: enabled
          ? 'IPv6 enabled via networksetup (${applied.join(', ')}).'
          : 'IPv6 disabled via networksetup (${applied.join(', ')}).',
      metadata: {
        'commands': commands.join('; '),
        'applied': applied.join(', '),
        if (skipped.isNotEmpty) 'skipped': skipped.join('; '),
        'mode': enabled ? 'automatic' : 'off',
      },
    );
  }

  /// Returns `(failure, null)` or `(null, services)`.
  Future<(FixResult?, List<String>?)> _listNetworkServices(
    FixActionKind kind,
    String verb,
  ) async {
    const command = 'networksetup -listallnetworkservices';
    late final ProcessResult result;
    try {
      result = await _runner('networksetup', ['-listallnetworkservices']);
    } on Object catch (error) {
      return (
        FixResult.failure(
          kind,
          message: 'Failed to $verb IPv6.',
          error: error.toString(),
          executed: false,
          metadata: {'command': command},
        ),
        null,
      );
    }

    final stderr = _asTrimmedString(result.stderr);
    final stdout = _asTrimmedString(result.stdout);

    if (result.exitCode != 0) {
      final detail = stderr.isNotEmpty
          ? stderr
          : (stdout.isNotEmpty ? stdout : 'exit code ${result.exitCode}');
      return (
        FixResult.failure(
          kind,
          message: 'Failed to $verb IPv6.',
          error: detail,
          metadata: {
            'command': command,
            'exitCode': '${result.exitCode}',
          },
        ),
        null,
      );
    }

    return (null, _parseNetworkServices(stdout));
  }

  /// Parses `networksetup -listallnetworkservices` output.
  ///
  /// Skips the header note and disabled services (lines prefixed with `*`).
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

  static String _asTrimmedString(Object? value) => value.toString().trim();
}
