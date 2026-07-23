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
  /// Options shown in the Network Controls radio group.
  static const selectableOptions = <Ipv6Preference>[
    Ipv6Preference.automatic,
    Ipv6Preference.preferIpv4,
  ];

  /// Status chip label for the detected configuration.
  String get statusLabel => switch (this) {
        Ipv6Preference.automatic => 'Automatic',
        Ipv6Preference.preferIpv4 => 'Prefer IPv4',
        Ipv6Preference.disableIpv6 => 'IPv6 off',
        Ipv6Preference.unknown => 'Unknown',
      };

  /// Radio option title.
  String get optionLabel => switch (this) {
        Ipv6Preference.automatic => 'Automatic',
        Ipv6Preference.preferIpv4 => 'Prefer IPv4',
        Ipv6Preference.disableIpv6 => 'Prefer IPv4',
        Ipv6Preference.unknown => 'Unknown',
      };

  /// Short helper text under a selectable radio option.
  String? get optionDescription => switch (this) {
        Ipv6Preference.automatic =>
          'Use your system defaults for IPv4 and IPv6.',
        Ipv6Preference.preferIpv4 =>
          'Use IPv4 when IPv6 is slow. Temporarily disables IPv6.',
        _ => null,
      };

  /// Whether this value can be chosen as a target mode.
  bool get isSelectable =>
      this == Ipv6Preference.automatic ||
      this == Ipv6Preference.preferIpv4;

  /// Maps detected / legacy values to a radio selection.
  Ipv6Preference get normalizedSelection => switch (this) {
        Ipv6Preference.preferIpv4 || Ipv6Preference.disableIpv6 =>
          Ipv6Preference.preferIpv4,
        Ipv6Preference.automatic => Ipv6Preference.automatic,
        _ => Ipv6Preference.automatic,
      };
}

/// Parses a persisted preference name, or null when invalid / missing.
Ipv6Preference? parseStoredIpv6Preference(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == Ipv6Preference.disableIpv6.name) {
    return Ipv6Preference.preferIpv4;
  }
  for (final preference in Ipv6PreferenceLabels.selectableOptions) {
    if (preference.name == value) {
      return preference;
    }
  }
  return null;
}
