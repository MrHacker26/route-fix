import '../../../domain/autofix/models/fix_action.dart';

/// Describes administrator privilege needs for Windows Auto Fix actions.
///
/// Detection is declarative for IPv6 binding changes — no elevation probe is
/// executed unless an [WindowsElevationProbe] is supplied.
final class WindowsAdminRequirement {
  const WindowsAdminRequirement({
    required this.required,
    this.isElevated,
    this.reason,
  });

  /// Whether the fix requires administrator privileges when applied.
  final bool required;

  /// Current process elevation when known; `null` if not probed.
  final bool? isElevated;

  final String? reason;

  /// Adapter IPv6 binding changes always require admin when executed.
  static const ipv6AdapterBinding = WindowsAdminRequirement(
    required: true,
    reason:
        'Changing NetAdapterBinding for ms_tcpip6 requires administrator privileges.',
  );

  bool get needsElevationToApply {
    if (!required) return false;
    if (isElevated == null) return true;
    return !isElevated!;
  }
}

/// Optional probe for whether the current process is elevated.
///
/// Must not run Auto Fix commands — only privilege inspection.
typedef WindowsElevationProbe = Future<bool> Function();

/// Resolves [WindowsAdminRequirement] for a given [FixActionKind].
final class WindowsAdminRequirementResolver {
  const WindowsAdminRequirementResolver({
    this._elevationProbe,
  });

  final WindowsElevationProbe? _elevationProbe;

  Future<WindowsAdminRequirement> forAction(FixActionKind kind) async {
    final base = switch (kind) {
      FixActionKind.disableIpv6 || FixActionKind.enableIpv6 =>
        WindowsAdminRequirement.ipv6AdapterBinding,
      FixActionKind.flushDns ||
      FixActionKind.changeDnsCloudflare =>
        WindowsAdminRequirement.ipv6AdapterBinding,
      FixActionKind.openWarp =>
        const WindowsAdminRequirement(required: false),
    };

    if (!base.required || _elevationProbe == null) {
      return base;
    }

    final elevated = await _elevationProbe();
    return WindowsAdminRequirement(
      required: base.required,
      isElevated: elevated,
      reason: base.reason,
    );
  }
}
