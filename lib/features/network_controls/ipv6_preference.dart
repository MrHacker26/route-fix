/// Manual IPv6 preference modes for Network Controls.
enum Ipv6Preference {
  /// OS default / automatic configuration.
  automatic,

  /// Prefer IPv4 paths (soft wording; may disable IPv6 under the hood).
  preferIpv4,

  /// Explicitly disable IPv6 on supported platforms.
  disableIpv6,

  /// Detection unsupported or inconclusive.
  unknown,
}

extension Ipv6PreferenceLabels on Ipv6Preference {
  /// Status chip label for the detected configuration.
  String get statusLabel => switch (this) {
        Ipv6Preference.automatic => 'Automatic',
        Ipv6Preference.preferIpv4 => 'Preferred IPv4',
        Ipv6Preference.disableIpv6 => 'IPv6 Disabled',
        Ipv6Preference.unknown => 'Unknown',
      };

  /// Radio option title.
  String get optionLabel => switch (this) {
        Ipv6Preference.automatic => 'Automatic (Recommended)',
        Ipv6Preference.preferIpv4 => 'Prefer IPv4',
        Ipv6Preference.disableIpv6 => 'Disable IPv6',
        Ipv6Preference.unknown => 'Unknown',
      };

  /// Whether this value can be chosen as a target mode.
  bool get isSelectable =>
      this == Ipv6Preference.automatic ||
      this == Ipv6Preference.preferIpv4 ||
      this == Ipv6Preference.disableIpv6;
}
