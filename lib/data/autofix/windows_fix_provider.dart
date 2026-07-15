import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_provider.dart';
import 'windows/windows_admin_requirement.dart';
import 'windows/windows_ipv6_fix_commands.dart';

/// Windows Auto Fix adapter.
///
/// Prepares PowerShell / `netsh` commands for IPv6 fixes through the
/// [FixProvider] interface. Does **not** execute them automatically.
final class WindowsFixProvider extends PlatformFixProvider {
  const WindowsFixProvider({
    this._commands = const WindowsIpv6FixCommands(),
    this._adminResolver = const WindowsAdminRequirementResolver(),
  });

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
            title: action.title,
            description: action.description,
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
    return switch (kind) {
      FixActionKind.disableIpv6 => _planIpv6(enabled: false),
      FixActionKind.enableIpv6 => _planIpv6(enabled: true),
      FixActionKind.flushDns || FixActionKind.openWarp =>
        FixResult.notImplemented(kind),
    };
  }

  Future<FixResult> _planIpv6({required bool enabled}) async {
    final kind =
        enabled ? FixActionKind.enableIpv6 : FixActionKind.disableIpv6;
    final admin = await _adminResolver.forAction(kind);
    final command = _commands.primaryCommand(enable: enabled);
    final netsh =
        enabled ? _commands.enableIpv6Netsh() : _commands.disableIpv6Netsh();

    if (!admin.required) {
      return FixResult.planned(
        kind,
        success: false,
        message: 'Failed to prepare Windows IPv6 fix.',
        error: 'Administrator requirement could not be determined.',
        executedCommand: command,
        platform: FixPlatform.windows,
        requiresElevation: false,
      );
    }

    final verb = enabled ? 'enable' : 'disable';
    final elevationNote = admin.isElevated == null
        ? 'Administrator privileges are required to apply this fix.'
        : (admin.isElevated!
            ? 'Current process is elevated; command is ready to apply.'
            : 'Current process is not elevated; elevate before applying.');

    return FixResult.planned(
      kind,
      message:
          'Prepared Windows command to $verb IPv6 via PowerShell NetAdapterBinding. '
          '$elevationNote Command was not executed.',
      executedCommand: command,
      platform: FixPlatform.windows,
      requiresElevation: admin.needsElevationToApply,
      metadata: {
        'powershell': command,
        'netsh': netsh,
        'componentId': 'ms_tcpip6',
        'adminRequired': '${admin.required}',
        if (admin.isElevated != null) 'isElevated': '${admin.isElevated}',
        if (admin.reason != null) 'adminReason': admin.reason!,
        'execution': 'deferred',
      },
    );
  }
}
