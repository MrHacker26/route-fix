/// Identifiers for Auto Fix capabilities.
enum FixActionKind {
  /// Prefer IPv4 by disabling IPv6 on the active stack.
  disableIpv6,

  /// Re-enable IPv6 if previously disabled.
  enableIpv6,

  /// Clear local DNS caches. Reserved for a future release.
  flushDns,

  /// Launch Cloudflare WARP. Reserved for a future release.
  openWarp,
}

/// Desktop platforms RouteFix can target for Auto Fix.
enum FixPlatform {
  linux,
  macOS,
  windows,

  /// Host OS is not a known Auto Fix target (reserved for future platforms).
  unsupported,
}

/// Availability of an action on the current host.
enum FixAvailability {
  /// Ready to run once an implementation is wired.
  available,

  /// Not supported on this platform.
  unsupported,

  /// Planned — not implemented yet.
  comingSoon,

  /// Supported but requires elevated privileges when executed.
  requiresElevation,
}

/// Declarative description of a single Auto Fix capability.
///
/// Immutable — no side effects.
final class FixAction {
  const FixAction({
    required this.kind,
    required this.title,
    required this.description,
    required this.availability,
    required this.supportedPlatforms,
    this.relatedIssueCodes = const [],
  });

  final FixActionKind kind;
  final String title;
  final String description;
  final FixAvailability availability;
  final Set<FixPlatform> supportedPlatforms;

  /// Optional links to [DiagnosticIssue.code] values that may suggest this fix.
  final List<String> relatedIssueCodes;

  String get id => kind.name;

  bool supportsPlatform(FixPlatform platform) =>
      supportedPlatforms.contains(platform);

  @override
  bool operator ==(Object other) {
    return other is FixAction &&
        other.kind == kind &&
        other.title == title &&
        other.description == description &&
        other.availability == availability &&
        _setEquals(other.supportedPlatforms, supportedPlatforms) &&
        _listEquals(other.relatedIssueCodes, relatedIssueCodes);
  }

  @override
  int get hashCode => Object.hash(
        kind,
        title,
        description,
        availability,
        Object.hashAll(supportedPlatforms),
        Object.hashAll(relatedIssueCodes),
      );
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
