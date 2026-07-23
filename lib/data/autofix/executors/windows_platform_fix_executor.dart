import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';
import '../../../domain/autofix/shell_command_executor.dart';
import 'windows_privileged_powershell.dart';

/// Windows Auto Fix executor using elevated PowerShell NetAdapterBinding.
///
/// Discovers adapters dynamically — never hardcodes adapter names.
final class WindowsPlatformFixExecutor implements PlatformFixExecutor {
  WindowsPlatformFixExecutor({
    required ShellCommandExecutor shell,
    WindowsPrivilegedPowerShell? privileged,
  }) : _privileged = privileged ?? WindowsPrivilegedPowerShell(shell: shell);

  final WindowsPrivilegedPowerShell _privileged;

  static const _componentId = 'ms_tcpip6';

  static const _disableScript =
      r'Get-NetAdapter | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }';

  static const _enableScript =
      r'Get-NetAdapter | ForEach-Object { Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }';

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
    final script = enabled ? _enableScript : _disableScript;
    const executedCommand = 'powershell.exe -Verb RunAs';

    late final WindowsPrivilegedCommandResult result;
    try {
      result = await _privileged.runScript(script);
    } on AutoFixException catch (error) {
      return FixResult.failure(
        kind,
        message: 'Couldn’t update network settings.',
        error: error.message,
        executed: false,
        platform: platform,
        requiresElevation: true,
        metadata: {
          'command': executedCommand,
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
          'command': executedCommand,
          'componentId': _componentId,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
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
        metadata: {
          'command': executedCommand,
          'componentId': _componentId,
          if (result.stdout.isNotEmpty) 'stdout': result.stdout,
          if (result.stderr.isNotEmpty) 'stderr': result.stderr,
          'exitCode': '${result.exitCode}',
          'outcome': 'AuthFailed',
        },
      );
    }

    if (!result.isSuccess) {
      final detail = result.stderr.isNotEmpty
          ? result.stderr
          : (result.stdout.isNotEmpty
              ? result.stdout
              : 'exit code ${result.exitCode}');
      return FixResult.failure(
        kind,
        message: 'Couldn’t update network settings.',
        error: detail,
        platform: platform,
        requiresElevation: true,
        executedCommand: result.executedCommand,
        metadata: {
          'command': executedCommand,
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
      executedCommand: result.executedCommand,
      metadata: {
        'command': executedCommand,
        'componentId': _componentId,
        'elevated': 'true',
        if (result.stdout.isNotEmpty) 'stdout': result.stdout,
        if (result.stderr.isNotEmpty) 'stderr': result.stderr,
      },
    );
  }
}
