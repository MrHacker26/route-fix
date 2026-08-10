import '../../../domain/autofix/auto_fix_service.dart';
import '../../../domain/autofix/fix_provider.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_provider.dart';

/// Adapts [AutoFixService] to the existing [FixProvider] catalog API.
final class AutoFixProviderAdapter extends PlatformFixProvider {
  const AutoFixProviderAdapter({
    required AutoFixService service,
    this.platformOverride,
  }) : _service = service;

  final AutoFixService _service;
  final FixPlatform? platformOverride;

  @override
  FixPlatform get platform => platformOverride ?? _service.platform;

  @override
  Future<FixResult> applyStub(FixActionKind kind) {
    return _service.apply(kind.toFixType);
  }

  @override
  List<FixAction> availableActions() {
    final base = super.availableActions();
    return [
      for (final action in base)
        if (action.kind == FixActionKind.enableIpv6)
          FixAction(
            kind: action.kind,
            title: FixType.restoreDefault.displayTitle,
            description:
                'Undo temporary changes and return to normal settings.',
            availability: action.availability == FixAvailability.available &&
                    platform == FixPlatform.windows
                ? FixAvailability.requiresElevation
                : action.availability,
            supportedPlatforms: action.supportedPlatforms,
            relatedIssueCodes: action.relatedIssueCodes,
          )
        else if ((action.kind == FixActionKind.disableIpv6) &&
            platform == FixPlatform.windows)
          FixAction(
            kind: action.kind,
            title: action.title,
            description: action.description,
            availability: FixAvailability.requiresElevation,
            supportedPlatforms: action.supportedPlatforms,
            relatedIssueCodes: action.relatedIssueCodes,
          )
        else if (action.kind == FixActionKind.disableIpv6)
          FixAction(
            kind: action.kind,
            title: FixType.preferIpv4.displayTitle,
            description:
                'IPv6 looks unreliable on this network. Prefer IPv4 for now.',
            availability: action.availability,
            supportedPlatforms: action.supportedPlatforms,
            relatedIssueCodes: action.relatedIssueCodes,
          )
        else if (action.kind == FixActionKind.flushDns ||
            action.kind == FixActionKind.changeDnsCloudflare)
          FixAction(
            kind: action.kind,
            title: action.title,
            description: action.description,
            availability: FixAvailability.requiresElevation,
            supportedPlatforms: action.supportedPlatforms,
            relatedIssueCodes: action.relatedIssueCodes,
          )
        else
          action,
    ];
  }
}
