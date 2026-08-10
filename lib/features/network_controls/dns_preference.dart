import '../../domain/autofix/dns_presets.dart';

/// User-facing DNS resolver choice in Network Controls.
enum DnsPreference {
  unknown,
  automatic,
  cloudflare,
}

extension DnsPreferenceLabels on DnsPreference {
  bool get isSelectable =>
      this == DnsPreference.automatic || this == DnsPreference.cloudflare;

  DnsPreference get normalizedSelection => switch (this) {
        DnsPreference.unknown => DnsPreference.automatic,
        _ => this,
      };

  String get statusLabel => switch (this) {
        DnsPreference.automatic => 'Automatic',
        DnsPreference.cloudflare => 'Cloudflare',
        DnsPreference.unknown => 'Unknown',
      };

  String get optionLabel => statusLabel;

  String? get optionDescription => switch (this) {
        DnsPreference.automatic =>
          'Use DNS from your router or ISP (DHCP).',
        DnsPreference.cloudflare => 'Use 1.1.1.1 and 1.0.0.1.',
        DnsPreference.unknown => null,
      };

  static const selectableOptions = [
    DnsPreference.automatic,
    DnsPreference.cloudflare,
  ];
}

DnsPreference? parseStoredDnsPreference(String? raw) {
  if (raw == null) return null;
  for (final value in DnsPreference.values) {
    if (value.name == raw) return value;
  }
  return null;
}

bool dnsServersMatchCloudflare(Iterable<String> servers) =>
    DnsPresets.isCloudflareServers(servers);
