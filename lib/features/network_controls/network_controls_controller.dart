import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_executor.dart';
import 'ipv6_preference.dart';
import 'ipv6_preference_probe.dart';

/// Orchestrates Network Controls against existing Auto Fix infrastructure.
final class NetworkControlsController {
  NetworkControlsController({
    required AutoFixService autoFix,
    required Ipv6PreferenceProbe probe,
  })  : _autoFix = autoFix,
        _probe = probe;

  final AutoFixService _autoFix;
  final Ipv6PreferenceProbe _probe;

  Ipv6Preference _detected = Ipv6Preference.unknown;
  Ipv6Preference _selected = Ipv6Preference.automatic;
  Ipv6Preference? _rememberedMode;
  String? _statusDetail;
  var _loading = false;
  var _applying = false;

  Ipv6Preference get detected => _detected;
  Ipv6Preference get selected => _selected;
  String? get statusDetail => _statusDetail;
  bool get isLoading => _loading;
  bool get isApplying => _applying;
  bool get isBusy => _applying || _autoFix.isBusy;

  /// True when the selection differs from the detected baseline.
  bool get hasPendingChanges {
    if (!_selected.isSelectable) return false;
    if (_detected == Ipv6Preference.unknown) {
      return _selected != Ipv6Preference.automatic;
    }
    return _selected != _detected;
  }

  bool get supportsPlatform =>
      _autoFix.supports(FixType.preferIpv4) ||
      _autoFix.supports(FixType.restoreDefault);

  Future<void> load() async {
    _loading = true;
    try {
      final result = await _probe.detect();
      var preference = result.preference;
      if (_rememberedMode != null &&
          (preference == Ipv6Preference.disableIpv6 ||
              preference == Ipv6Preference.preferIpv4)) {
        preference = _rememberedMode!;
      }
      _detected = preference;
      _statusDetail = result.detail;
      _selected = preference.isSelectable
          ? preference
          : Ipv6Preference.automatic;
    } finally {
      _loading = false;
    }
  }

  void select(Ipv6Preference preference) {
    if (!preference.isSelectable || _applying) return;
    _selected = preference;
  }

  Future<FixResult> applySelection({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    if (!hasPendingChanges || _applying) {
      return FixResult.failure(
        FixActionKind.disableIpv6,
        message: 'Nothing to apply.',
        executed: false,
        platform: _autoFix.platform,
      );
    }

    _applying = true;
    try {
      final result = switch (_selected) {
        Ipv6Preference.automatic => await _autoFix.restoreDefault(
            onPhase: onPhase,
          ),
        Ipv6Preference.preferIpv4 || Ipv6Preference.disableIpv6 =>
          await _autoFix.apply(
            FixType.preferIpv4,
            onPhase: onPhase,
          ),
        Ipv6Preference.unknown => FixResult.failure(
            FixActionKind.disableIpv6,
            message: 'Choose a preference first.',
            executed: false,
            platform: _autoFix.platform,
          ),
      };

      if (result.success) {
        _rememberedMode =
            _selected == Ipv6Preference.automatic ? null : _selected;
        await load();
      }
      return result;
    } finally {
      _applying = false;
    }
  }

  Future<FixResult> restoreDefaults({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    _applying = true;
    try {
      final result = await _autoFix.restoreDefault(onPhase: onPhase);
      if (result.success) {
        _rememberedMode = null;
        _selected = Ipv6Preference.automatic;
        await load();
      }
      return result;
    } finally {
      _applying = false;
    }
  }
}
