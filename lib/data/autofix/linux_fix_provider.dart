import 'dart:io';

import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_provider.dart';

/// Runs a host process for Linux Auto Fix adapters.
typedef LinuxFixProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Linux Auto Fix adapter.
///
/// Currently implements [FixActionKind.disableIpv6] via `sysctl`.
final class LinuxFixProvider extends PlatformFixProvider {
  const LinuxFixProvider({
    this._runProcess,
  });

  final LinuxFixProcessRunner? _runProcess;

  LinuxFixProcessRunner get _runner =>
      _runProcess ?? ((executable, arguments) => Process.run(executable, arguments));

  @override
  FixPlatform get platform => FixPlatform.linux;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return switch (kind) {
      FixActionKind.disableIpv6 => _disableIpv6(),
      FixActionKind.enableIpv6 ||
      FixActionKind.flushDns ||
      FixActionKind.openWarp =>
        FixResult.notImplemented(kind),
    };
  }

  /// Prefer IPv4 by disabling IPv6 for all and default interfaces.
  ///
  /// Uses:
  /// `sysctl -w net.ipv6.conf.all.disable_ipv6=1`
  /// `sysctl -w net.ipv6.conf.default.disable_ipv6=1`
  Future<FixResult> _disableIpv6() async {
    const kind = FixActionKind.disableIpv6;
    const settings = <String>[
      'net.ipv6.conf.all.disable_ipv6=1',
      'net.ipv6.conf.default.disable_ipv6=1',
    ];

    final stdoutParts = <String>[];

    for (final setting in settings) {
      final command = 'sysctl -w $setting';
      late final ProcessResult result;
      try {
        result = await _runner('sysctl', ['-w', setting]);
      } on Object catch (error) {
        return FixResult.failure(
          kind,
          message: 'Failed to disable IPv6.',
          error: error.toString(),
          executed: false,
          metadata: {'command': command},
        );
      }

      final stderr = _asTrimmedString(result.stderr);
      final stdout = _asTrimmedString(result.stdout);

      if (result.exitCode != 0) {
        final detail = stderr.isNotEmpty
            ? stderr
            : (stdout.isNotEmpty ? stdout : 'exit code ${result.exitCode}');
        return FixResult.failure(
          kind,
          message: 'Failed to disable IPv6.',
          error: detail,
          metadata: {
            'command': command,
            'exitCode': '${result.exitCode}',
          },
        );
      }

      if (stdout.isNotEmpty) {
        stdoutParts.add(stdout);
      }
    }

    return FixResult.success(
      kind,
      message: 'IPv6 disabled via sysctl (all and default).',
      metadata: {
        'commands': settings.map((s) => 'sysctl -w $s').join('; '),
        if (stdoutParts.isNotEmpty) 'stdout': stdoutParts.join('\n'),
      },
    );
  }

  static String _asTrimmedString(Object? value) => value.toString().trim();
}
