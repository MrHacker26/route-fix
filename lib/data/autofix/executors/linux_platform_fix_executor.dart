import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';
import '../../../domain/autofix/shell_command_executor.dart';

/// Linux Auto Fix executor using `sysctl` (Ubuntu/Debian/Fedora/Arch).
final class LinuxPlatformFixExecutor implements PlatformFixExecutor {
  LinuxPlatformFixExecutor({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

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
      type == FixType.preferIpv4 || type == FixType.restoreDefault;

  @override
  Future<FixResult> apply(FixType type) async {
    return switch (type) {
      FixType.preferIpv4 => _applySysctl(
          kind: FixActionKind.disableIpv6,
          settings: _preferSettings,
          successMessage: 'Prefer IPv4 applied via sysctl.',
        ),
      FixType.restoreDefault => _applySysctl(
          kind: FixActionKind.enableIpv6,
          settings: _restoreSettings,
          successMessage: 'Network defaults restored via sysctl.',
        ),
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
    final stdoutParts = <String>[];
    final stderrParts = <String>[];
    final commands = <String>[];

    for (final setting in settings) {
      if (!_isSafeSysctlAssignment(setting)) {
        throw const AutoFixValidationException(
          'Rejected unsafe sysctl assignment.',
        );
      }
      final args = ['-w', setting];
      commands.add('sysctl ${args.join(' ')}');

      late final ShellCommandResult result;
      try {
        result = await _shell.run('sysctl', args);
      } on AutoFixException catch (error) {
        return FixResult.failure(
          kind,
          message: 'Could not update network settings.',
          error: error.message,
          executed: false,
          platform: platform,
          requiresElevation: true,
          metadata: {
            'command': 'sysctl ${args.join(' ')}',
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
        final permission = detail.toLowerCase().contains('permission') ||
            detail.toLowerCase().contains('not permitted');
        return FixResult.failure(
          kind,
          message: permission
              ? 'RouteFix needs administrator permission to continue.'
              : 'Could not update network settings.',
          error: detail,
          platform: platform,
          requiresElevation: true,
          metadata: {
            'commands': commands.join('; '),
            'exitCode': '${result.exitCode}',
            if (stdoutParts.isNotEmpty) 'stdout': stdoutParts.join('\n'),
            if (stderrParts.isNotEmpty) 'stderr': stderrParts.join('\n'),
          },
        );
      }
    }

    return FixResult.success(
      kind,
      message: successMessage,
      platform: platform,
      requiresElevation: true,
      metadata: {
        'commands': commands.join('; '),
        if (stdoutParts.isNotEmpty) 'stdout': stdoutParts.join('\n'),
        if (stderrParts.isNotEmpty) 'stderr': stderrParts.join('\n'),
      },
    );
  }

  static bool _isSafeSysctlAssignment(String setting) {
    return RegExp(
      r'^net\.ipv6\.conf\.(all|default)\.disable_ipv6=[01]$',
    ).hasMatch(setting);
  }
}
