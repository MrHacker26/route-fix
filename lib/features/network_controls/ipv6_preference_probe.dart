import 'dart:io';

import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/shell_command_executor.dart';
import 'ipv6_preference.dart';

/// Result of probing the host’s current IPv6 preference.
final class Ipv6PreferenceProbeResult {
  const Ipv6PreferenceProbeResult({
    required this.preference,
    this.detail,
  });

  final Ipv6Preference preference;
  final String? detail;
}

/// Read-only detection of IPv6 preference — never mutates configuration.
///
/// Apply / restore still go exclusively through [AutoFixService].
final class Ipv6PreferenceProbe {
  Ipv6PreferenceProbe({
    required ShellCommandExecutor shell,
    required AutoFixService autoFix,
    FixPlatform? platformOverride,
  })  : _shell = shell,
        _autoFix = autoFix,
        _platformOverride = platformOverride;

  final ShellCommandExecutor _shell;
  final AutoFixService _autoFix;
  final FixPlatform? _platformOverride;

  Future<Ipv6PreferenceProbeResult> detect() async {
    final platform = _platformOverride ?? _autoFix.platform;
    try {
      return switch (platform) {
        FixPlatform.macOS => await _detectMacOs(),
        FixPlatform.linux => await _detectLinux(),
        FixPlatform.windows => await _detectWindows(),
        FixPlatform.unsupported => const Ipv6PreferenceProbeResult(
            preference: Ipv6Preference.unknown,
            detail: 'Network Controls are not available on this platform.',
          ),
      };
    } on Object {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.unknown,
        detail: 'Could not detect the current configuration.',
      );
    }
  }

  Future<Ipv6PreferenceProbeResult> _detectMacOs() async {
    final services = await _listMacServices();
    if (services.isEmpty) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.unknown,
        detail: 'No network services found.',
      );
    }

    final modes = <String>[];
    for (final service in services) {
      final info = await _shell.run('networksetup', ['-getinfo', service]);
      if (!info.isSuccess) continue;
      final mode = _parseMacIpv6Mode(info.stdout);
      if (mode != null) modes.add(mode);
    }

    if (modes.isEmpty) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.unknown,
      );
    }

    final offCount = modes.where((m) => m == 'off').length;
    final automaticCount = modes.where((m) => m == 'automatic').length;

    if (offCount == modes.length) {
      final fromAutoFix = _autoFix.appliedFixes.any(
        (fix) => fix.type == FixType.preferIpv4,
      );
      return Ipv6PreferenceProbeResult(
        preference: fromAutoFix
            ? Ipv6Preference.preferIpv4
            : Ipv6Preference.disableIpv6,
        detail: fromAutoFix
            ? 'Prefer IPv4 is on.'
            : 'IPv6 is off.',
      );
    }
    if (automaticCount == modes.length) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.automatic,
        detail: 'IPv6 is automatic.',
      );
    }
    return const Ipv6PreferenceProbeResult(
      preference: Ipv6Preference.unknown,
      detail: 'IPv6 settings differ across services.',
    );
  }

  Future<List<String>> _listMacServices() async {
    final listed = await _shell.run(
      'networksetup',
      const ['-listallnetworkservices'],
    );
    if (!listed.isSuccess) return const [];
    final services = <String>[];
    for (final raw in listed.stdout.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().startsWith('an asterisk')) continue;
      if (line.startsWith('*')) continue;
      services.add(line);
    }
    return services;
  }

  static String? _parseMacIpv6Mode(String stdout) {
    for (final raw in stdout.split('\n')) {
      final line = raw.trim().toLowerCase();
      if (!line.startsWith('ipv6:')) continue;
      final value = line.substring('ipv6:'.length).trim();
      if (value.contains('off')) return 'off';
      if (value.contains('automatic')) return 'automatic';
      if (value.contains('link-local')) return 'link-local';
      if (value.contains('manual')) return 'manual';
      return value;
    }
    return null;
  }

  Future<Ipv6PreferenceProbeResult> _detectLinux() async {
    final result = await _shell.run(
      'sysctl',
      const ['-n', 'net.ipv6.conf.all.disable_ipv6'],
    );
    if (!result.isSuccess) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.unknown,
      );
    }
    final value = result.stdout.trim();
    if (value == '1') {
      final fromAutoFix = _autoFix.appliedFixes.any(
        (fix) => fix.type == FixType.preferIpv4,
      );
      return Ipv6PreferenceProbeResult(
        preference: fromAutoFix
            ? Ipv6Preference.preferIpv4
            : Ipv6Preference.disableIpv6,
      );
    }
    if (value == '0') {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.automatic,
      );
    }
    return const Ipv6PreferenceProbeResult(
      preference: Ipv6Preference.unknown,
    );
  }

  Future<Ipv6PreferenceProbeResult> _detectWindows() async {
    const script =
        r'(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | '
        r'Measure-Object -Property Enabled -Average).Average';
    final result = await _shell.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]);
    if (!result.isSuccess || result.stdout.trim().isEmpty) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.unknown,
      );
    }
    final avg = double.tryParse(result.stdout.trim());
    if (avg == null) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.unknown,
      );
    }
    if (avg <= 0.01) {
      final fromAutoFix = _autoFix.appliedFixes.any(
        (fix) => fix.type == FixType.preferIpv4,
      );
      return Ipv6PreferenceProbeResult(
        preference: fromAutoFix
            ? Ipv6Preference.preferIpv4
            : Ipv6Preference.disableIpv6,
      );
    }
    if (avg >= 0.99) {
      return const Ipv6PreferenceProbeResult(
        preference: Ipv6Preference.automatic,
      );
    }
    return const Ipv6PreferenceProbeResult(
      preference: Ipv6Preference.unknown,
      detail: 'Mixed IPv6 binding across adapters.',
    );
  }

  /// Host platform for tests when [AutoFixService] is not available.
  static FixPlatform detectHostPlatform() {
    if (Platform.isMacOS) return FixPlatform.macOS;
    if (Platform.isLinux) return FixPlatform.linux;
    if (Platform.isWindows) return FixPlatform.windows;
    return FixPlatform.unsupported;
  }
}
