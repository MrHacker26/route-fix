import 'fix_provider.dart';
import 'models/fix_action.dart';
import 'models/fix_result.dart';

/// Shared Auto Fix catalog + platform gating.
///
/// Concrete Linux / macOS / Windows providers extend this type.
/// No provider in the foundation layer executes system commands.
abstract base class PlatformFixProvider implements FixProvider {
  const PlatformFixProvider();

  /// Canonical actions RouteFix knows about.
  static const List<FixAction> catalog = [
    FixAction(
      kind: FixActionKind.disableIpv6,
      title: 'Disable IPv6',
      description:
          'Prefer IPv4 when IPv6 paths are unavailable or pathological.',
      availability: FixAvailability.available,
      supportedPlatforms: {
        FixPlatform.linux,
        FixPlatform.macOS,
        FixPlatform.windows,
      },
      relatedIssueCodes: ['ipv6_unavailable', 'ipv6_latency'],
    ),
    FixAction(
      kind: FixActionKind.enableIpv6,
      title: 'Enable IPv6',
      description: 'Restore IPv6 if it was previously disabled.',
      availability: FixAvailability.available,
      supportedPlatforms: {
        FixPlatform.linux,
        FixPlatform.macOS,
        FixPlatform.windows,
      },
      relatedIssueCodes: ['ipv6_unavailable'],
    ),
    FixAction(
      kind: FixActionKind.flushDns,
      title: 'Flush DNS',
      description: 'Clear local DNS caches after resolver changes.',
      availability: FixAvailability.comingSoon,
      supportedPlatforms: {
        FixPlatform.linux,
        FixPlatform.macOS,
        FixPlatform.windows,
      },
      relatedIssueCodes: ['dns_failure'],
    ),
    FixAction(
      kind: FixActionKind.openWarp,
      title: 'Open WARP',
      description: 'Launch Cloudflare WARP when edge routing may help.',
      availability: FixAvailability.comingSoon,
      supportedPlatforms: {
        FixPlatform.linux,
        FixPlatform.macOS,
        FixPlatform.windows,
      },
    ),
  ];

  @override
  List<FixAction> availableActions() {
    return [
      for (final action in catalog)
        FixAction(
          kind: action.kind,
          title: action.title,
          description: action.description,
          availability: _availabilityFor(action),
          supportedPlatforms: action.supportedPlatforms,
          relatedIssueCodes: action.relatedIssueCodes,
        ),
    ];
  }

  @override
  bool supports(FixActionKind kind) {
    final action = _find(kind);
    if (action == null) return false;
    if (!action.supportsPlatform(platform)) return false;
    return action.availability != FixAvailability.unsupported;
  }

  @override
  Future<FixResult> apply(FixActionKind kind) async {
    final action = _find(kind);
    if (action == null) {
      return FixResult.notImplemented(kind);
    }

    if (!action.supportsPlatform(platform)) {
      return FixResult.unsupported(kind, platform);
    }

    return switch (action.availability) {
      FixAvailability.comingSoon => FixResult.comingSoon(kind),
      FixAvailability.unsupported => FixResult.unsupported(kind, platform),
      FixAvailability.available || FixAvailability.requiresElevation =>
        // Foundation: never mutate the host.
        applyStub(kind),
    };
  }

  /// Platform-specific hook. Must not run system commands in the foundation.
  Future<FixResult> applyStub(FixActionKind kind);

  FixAvailability _availabilityFor(FixAction action) {
    if (!action.supportsPlatform(platform)) {
      return FixAvailability.unsupported;
    }
    return action.availability;
  }

  FixAction? _find(FixActionKind kind) {
    for (final action in catalog) {
      if (action.kind == kind) return action;
    }
    return null;
  }
}
