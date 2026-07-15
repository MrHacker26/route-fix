import 'fix_provider.dart';
import 'models/fix_action.dart';
import 'models/fix_result.dart';

/// Shared Auto Fix catalog + platform gating.
///
/// Concrete Linux / macOS / Windows providers extend this type.
/// Platform adapters may execute system commands from [applyStub].
abstract base class PlatformFixProvider implements FixProvider {
  const PlatformFixProvider();

  /// Canonical actions RouteFix knows about.
  static const List<FixAction> catalog = [
    FixAction(
      kind: FixActionKind.disableIpv6,
      title: 'Prefer IPv4',
      description:
          'IPv6 looks unreliable on this network. Prefer IPv4 for now.',
      availability: FixAvailability.available,
      supportedPlatforms: {
        FixPlatform.linux,
        FixPlatform.macOS,
        FixPlatform.windows,
      },
      relatedIssueCodes: ['ipv6_latency'],
    ),
    FixAction(
      kind: FixActionKind.enableIpv6,
      title: 'Restore defaults',
      description: 'Undo temporary changes and return to normal settings.',
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
      description: 'Clear cached name lookups after network changes.',
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
      description: 'Try Cloudflare WARP when public routes feel congested.',
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
        applyStub(kind),
    };
  }

  /// Platform-specific hook — may run system commands when implemented.
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
