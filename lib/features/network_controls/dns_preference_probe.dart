import '../../data/autofix/shell/dart_io_shell_command_executor.dart';
import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/dns_presets.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/shell_command_executor.dart';
import 'dns_preference.dart';

/// Detects whether the host uses DHCP DNS or the Cloudflare preset.
final class DnsPreferenceProbe {
  DnsPreferenceProbe({
    ShellCommandExecutor? shell,
    AutoFixService? autoFix,
  })  : _shell = shell ?? const DartIoShellCommandExecutor(),
        _autoFix = autoFix;

  final ShellCommandExecutor _shell;
  final AutoFixService? _autoFix;

  Future<DnsPreferenceProbeResult> detect() async {
    final platform = _autoFix?.platform ?? FixPlatform.unsupported;
    return switch (platform) {
      FixPlatform.macOS => _detectMacOs(),
      FixPlatform.linux => _detectLinux(),
      FixPlatform.windows => _detectWindows(),
      FixPlatform.unsupported => const DnsPreferenceProbeResult(
          preference: DnsPreference.unknown,
          detail: 'DNS controls aren’t available here.',
        ),
    };
  }

  Future<DnsPreferenceProbeResult> _detectMacOs() async {
    final services = await _macServices();
    if (services.isEmpty) {
      return const DnsPreferenceProbeResult(
        preference: DnsPreference.unknown,
        detail: 'No network services found.',
      );
    }

    final servers = await _macDnsServers(services.first);
    if (servers.isEmpty) {
      return DnsPreferenceProbeResult(
        preference: DnsPreference.automatic,
        detail: '${services.first}: DHCP',
      );
    }
    if (dnsServersMatchCloudflare(servers)) {
      return DnsPreferenceProbeResult(
        preference: DnsPreference.cloudflare,
        detail: '${services.first}: ${DnsPresets.cloudflare.join(', ')}',
      );
    }
    return DnsPreferenceProbeResult(
      preference: DnsPreference.automatic,
      detail: '${services.first}: ${servers.join(', ')}',
    );
  }

  Future<DnsPreferenceProbeResult> _detectLinux() async {
    final link = await _linuxDefaultLink();
    if (link == null) {
      return const DnsPreferenceProbeResult(
        preference: DnsPreference.unknown,
        detail: 'No default route interface found.',
      );
    }
    final servers = await _linuxDnsServers(link);
    if (servers.isEmpty) {
      return DnsPreferenceProbeResult(
        preference: DnsPreference.automatic,
        detail: '$link: DHCP',
      );
    }
    if (dnsServersMatchCloudflare(servers)) {
      return DnsPreferenceProbeResult(
        preference: DnsPreference.cloudflare,
        detail: '$link: ${DnsPresets.cloudflare.join(', ')}',
      );
    }
    return DnsPreferenceProbeResult(
      preference: DnsPreference.automatic,
      detail: '$link: ${servers.join(', ')}',
    );
  }

  Future<DnsPreferenceProbeResult> _detectWindows() async {
    final adapter = await _windowsFirstAdapter();
    if (adapter == null) {
      return const DnsPreferenceProbeResult(
        preference: DnsPreference.unknown,
        detail: 'No active adapter found.',
      );
    }
    final servers = await _windowsDnsServers(adapter);
    if (servers.isEmpty) {
      return DnsPreferenceProbeResult(
        preference: DnsPreference.automatic,
        detail: '$adapter: DHCP',
      );
    }
    if (dnsServersMatchCloudflare(servers)) {
      return DnsPreferenceProbeResult(
        preference: DnsPreference.cloudflare,
        detail: '$adapter: ${DnsPresets.cloudflare.join(', ')}',
      );
    }
    return DnsPreferenceProbeResult(
      preference: DnsPreference.automatic,
      detail: '$adapter: ${servers.join(', ')}',
    );
  }

  Future<List<String>> _macServices() async {
    final result = await _shell.run('networksetup', ['-listallnetworkservices']);
    if (!result.isSuccess) return const [];
    final services = <String>[];
    for (final line in result.stdout.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.toLowerCase().startsWith('an asterisk')) continue;
      if (trimmed.startsWith('*')) continue;
      services.add(trimmed);
    }
    return services;
  }

  Future<List<String>> _macDnsServers(String service) async {
    final result =
        await _shell.run('networksetup', ['-getdnsservers', service]);
    if (!result.isSuccess) return const [];
    if (result.stdout.contains("There aren't any DNS Servers")) {
      return const [];
    }
    return [
      for (final line in result.stdout.split('\n'))
        if (_isIpv4(line.trim())) line.trim(),
    ];
  }

  Future<String?> _linuxDefaultLink() async {
    final result = await _shell.run('ip', ['-4', 'route', 'show', 'default']);
    if (!result.isSuccess) return null;
    for (final line in result.stdout.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5 && parts.first == 'default') return parts[4];
    }
    return null;
  }

  Future<List<String>> _linuxDnsServers(String link) async {
    final result = await _shell.run('resolvectl', ['dns', link]);
    if (!result.isSuccess) return const [];
    return [
      for (final match
          in RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b').allMatches(result.stdout))
        match.group(0)!,
    ];
  }

  Future<String?> _windowsFirstAdapter() async {
    const script =
        r"Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1 -ExpandProperty Name";
    final result = await _shell.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]);
    if (!result.isSuccess) return null;
    final name = result.stdout.trim();
    return name.isEmpty ? null : name;
  }

  Future<List<String>> _windowsDnsServers(String adapter) async {
    final escaped = adapter.replaceAll("'", "''");
    final script =
        "\$a = Get-NetAdapter -Name '$escaped' -ErrorAction SilentlyContinue; "
        'if (\$null -eq \$a) { exit 0 }; '
        '(Get-DnsClientServerAddress -InterfaceIndex \$a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join ","';
    final result = await _shell.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]);
    if (!result.isSuccess) return const [];
    final text = result.stdout.trim();
    if (text.isEmpty) return const [];
    return [
      for (final part in text.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static bool _isIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }
}

final class DnsPreferenceProbeResult {
  const DnsPreferenceProbeResult({
    required this.preference,
    this.detail,
  });

  final DnsPreference preference;
  final String? detail;
}
