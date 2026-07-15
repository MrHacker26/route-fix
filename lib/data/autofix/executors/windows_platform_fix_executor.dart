import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';
import '../../../domain/autofix/shell_command_executor.dart';

/// Windows Auto Fix executor using PowerShell NetAdapterBinding.
///
/// Discovers adapters dynamically — never hardcodes adapter names.
final class WindowsPlatformFixExecutor implements PlatformFixExecutor {
  WindowsPlatformFixExecutor({
    required ShellCommandExecutor shell,
  }) : _shell = shell;

  final ShellCommandExecutor _shell;

  static const _componentId = 'ms_tcpip6';

  @override
  FixPlatform get platform => FixPlatform.windows;

  @override
  bool supports(FixType type) =>
      type == FixType.preferIpv4 || type == FixType.restoreDefault;

  @override
  Future<FixResult> apply(FixType type) async {
    return switch (type) {
      FixType.preferIpv4 => _setIpv6Binding(enabled: false),
      FixType.restoreDefault => _setIpv6Binding(enabled: true),
      _ => FixResult.notImplemented(
          type.toFixActionKind ?? FixActionKind.disableIpv6,
        ),
    };
  }

  Future<FixResult> _setIpv6Binding({required bool enabled}) async {
    final kind =
        enabled ? FixActionKind.enableIpv6 : FixActionKind.disableIpv6;

    // Constant script — no user input interpolation.
    final script = enabled
        ? 'Get-NetAdapter | ForEach-Object { '
            'Enable-NetAdapterBinding -Name \$_.Name '
            '-ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }'
        : 'Get-NetAdapter | ForEach-Object { '
            'Disable-NetAdapterBinding -Name \$_.Name '
            '-ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }';

    final args = <String>[
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ];

    late final ShellCommandResult result;
    try {
      result = await _shell.run('powershell.exe', args);
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t update network settings.',
        error: error.message,
        executed: false,
        platform: platform,
        requiresElevation: true,
        metadata: {
          'command': resultCommand(args),
          if (error.details != null) 'details': error.details!,
        },
      );
    }

    if (!result.isSuccess) {
      final detail = result.stderr.isNotEmpty
          ? result.stderr
          : (result.stdout.isNotEmpty
              ? result.stdout
              : 'exit code ${result.exitCode}');
      final permission = detail.toLowerCase().contains('access') ||
          detail.toLowerCase().contains('denied') ||
          detail.toLowerCase().contains('administrator');
      return FixResult.failure(
        kind,
        message: permission
            ? 'Admin access is required.'
            : 'Couldn’t update network settings.',
        error: detail,
        platform: platform,
        requiresElevation: true,
        metadata: {
          'command': resultCommand(args),
          'exitCode': '${result.exitCode}',
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          'componentId': _componentId,
        },
      );
    }

    return FixResult.success(
      kind,
      message: enabled
          ? 'Defaults restored.'
          : 'Prefer IPv4 is on.',
      platform: platform,
      requiresElevation: true,
      executedCommand: resultCommand(args),
      metadata: {
        'command': resultCommand(args),
        'componentId': _componentId,
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
      },
    );
  }

  static String resultCommand(List<String> args) =>
      ['powershell.exe', ...args].join(' ');
}
