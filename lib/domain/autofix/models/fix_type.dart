import 'fix_action.dart';

/// Stable identifiers for Auto Fix capabilities.
///
/// Prefer these for new platform code. [FixActionKind] remains the catalog
/// bridge used by existing presentation / provider APIs.
enum FixType {
  /// Prefer IPv4 when the IPv6 path is broken or significantly slower.
  preferIpv4,

  /// Restore default network configuration for previously applied fixes.
  restoreDefault,

  /// Future: clear local DNS caches.
  flushDnsCache,

  /// Future: point resolvers at Cloudflare DNS.
  changeDnsCloudflare,

  /// Future: launch Cloudflare WARP if installed.
  enableWarp,

  /// Future: renew DHCP lease.
  renewDhcpLease,

  /// Future: bounce the active network interface.
  restartNetworkInterface,

  /// Future: reset OS network stack.
  resetNetworkStack,
}

/// Maps catalog [FixActionKind] values to [FixType].
extension FixActionKindMapping on FixActionKind {
  FixType get toFixType => switch (this) {
        FixActionKind.disableIpv6 => FixType.preferIpv4,
        FixActionKind.enableIpv6 => FixType.restoreDefault,
        FixActionKind.flushDns => FixType.flushDnsCache,
        FixActionKind.openWarp => FixType.enableWarp,
      };
}

/// Maps [FixType] back to catalog kinds when a catalog row exists.
extension FixTypeCatalogMapping on FixType {
  FixActionKind? get toFixActionKind => switch (this) {
        FixType.preferIpv4 => FixActionKind.disableIpv6,
        FixType.restoreDefault => FixActionKind.enableIpv6,
        FixType.flushDnsCache => FixActionKind.flushDns,
        FixType.enableWarp => FixActionKind.openWarp,
        FixType.changeDnsCloudflare ||
        FixType.renewDhcpLease ||
        FixType.restartNetworkInterface ||
        FixType.resetNetworkStack =>
          null,
      };

  /// Calm, user-facing title — never “Disable IPv6” for [preferIpv4].
  String get displayTitle => switch (this) {
        FixType.preferIpv4 => 'Prefer IPv4',
        FixType.restoreDefault => 'Restore Default Network Configuration',
        FixType.flushDnsCache => 'Flush DNS Cache',
        FixType.changeDnsCloudflare => 'Use Cloudflare DNS',
        FixType.enableWarp => 'Enable Cloudflare WARP',
        FixType.renewDhcpLease => 'Renew DHCP Lease',
        FixType.restartNetworkInterface => 'Restart Network Interface',
        FixType.resetNetworkStack => 'Reset Network Stack',
      };
}
