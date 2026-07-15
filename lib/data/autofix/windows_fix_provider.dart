import 'dart:io';

import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import '../../domain/autofix/shell_command_executor.dart';
import 'executors/windows_platform_fix_executor.dart';
import 'shell/dart_io_shell_command_executor.dart';
import 'windows/windows_admin_requirement.dart';
import 'windows/windows_ipv6_fix_commands.dart';

/// Runs a host process for Windows Auto Fix adapters.
typedef WindowsFixProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Windows Auto Fix adapter — executes PowerShell NetAdapterBinding via argv.
final class WindowsFixProvider extends PlatformFixProvider {
  WindowsFixProvider({
    WindowsFixProcessRunner? runProcess,
    ShellCommandExecutor? shell,
    WindowsIpv6FixCommands commands = const WindowsIpv6FixCommands(),
    WindowsAdminRequirementResolver adminResolver =
        const WindowsAdminRequirementResolver(),
  })  : _commands = commands,
        _adminResolver = adminResolver,
        _executor = WindowsPlatformFixExecutor(
          shell: shell ??
              DartIoShellCommandExecutor(
                runProcess: runProcess,
              ),
        );

  final WindowsPlatformFixExecutor _executor;
  final WindowsIpv6FixCommands _commands;
  final WindowsAdminRequirementResolver _adminResolver;

  @override
  FixPlatform get platform => FixPlatform.windows;

  @override
  List<FixAction> availableActions() {
    return [
      for (final action in super.availableActions())
        if (action.kind == FixActionKind.disableIpv6 ||
            action.kind == FixActionKind.enableIpv6)
          FixAction(
            kind: action.kind,
            title: action.kind == FixActionKind.disableIpv6
                ? FixType.preferIpv4.displayTitle
                : FixType.restoreDefault.displayTitle,
            description: action.kind == FixActionKind.disableIpv6
                ? 'RouteFix detected an IPv6 routing issue. '
                    'Temporarily preferring IPv4 may improve connectivity on this network.'
                : 'Undo Auto Fix changes and restore default network settings.',
            availability: FixAvailability.requiresElevation,
            supportedPlatforms: action.supportedPlatforms,
            relatedIssueCodes: action.relatedIssueCodes,
          )
        else
          action,
    ];
  }

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    // Still expose planned command metadata for debugging, then execute.
    final planned = await _planMetadata(kind);
    final result = await _executor.apply(kind.toFixType);
    if (!result.success) return result;
    return FixResult.success(
      kind,
      message: result.message ?? 'Network updated.',
      executedCommand: result.executedCommand ?? planned,
      platform: platform,
      requiresElevation: true,
      metadata: {
        ...result.metadata,
        if (planned != null) 'plannedCommand': planned,
      },
    );
  }

  Future<String?> _planMetadata(FixActionKind kind) async {
    if (kind != FixActionKind.disableIpv6 && kind != FixActionKind.enableIpv6) {
      return null;
    }
    final enabled = kind == FixActionKind.enableIpv6;
    final admin = await _adminResolver.forAction(kind);
    final command = _commands.primaryCommand(enable: enabled);
    return '$command (elevation=${admin.needsElevationToApply})';
  }
}
