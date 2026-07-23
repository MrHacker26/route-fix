import 'dart:async';

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
    Future<Ipv6Preference?> Function()? readSavedSelection,
    Future<void> Function(Ipv6Preference preference)? saveSelection,
  })  : _autoFix = autoFix,
        _probe = probe,
        _readSavedSelection = readSavedSelection,
        _saveSelection = saveSelection;

  final AutoFixService _autoFix;
  final Ipv6PreferenceProbe _probe;
  final Future<Ipv6Preference?> Function()? _readSavedSelection;
  final Future<void> Function(Ipv6Preference preference)? _saveSelection;

  Ipv6Preference _detected = Ipv6Preference.unknown;
  Ipv6Preference? _selected;
  String? _statusDetail;
  var _loading = false;
  var _applying = false;
  var _selectionApplied = false;

  /// OS-detected preference (shown in “Current state”).
  Ipv6Preference get detected => _detected;

  /// User choice — falls back to detected on first open when nothing is saved.
  Ipv6Preference? get selected => _selected;

  String? get statusDetail => _statusDetail;
  bool get isLoading => _loading;
  bool get isApplying => _applying;
  bool get isBusy => _applying || _autoFix.isBusy;

  /// True when the user picked something different from the detected baseline.
  bool get hasPendingChanges {
    if (_selectionApplied) return false;
    final choice = _selected;
    if (choice == null || !choice.isSelectable) return false;
    if (_detected == Ipv6Preference.unknown) {
      return choice != Ipv6Preference.automatic;
    }
    return !_matchesDetected(choice);
  }

  bool get supportsPlatform =>
      _autoFix.supports(FixType.preferIpv4) ||
      _autoFix.supports(FixType.restoreDefault);

  /// Probes the host and resolves the visible radio selection.
  Future<void> load() async {
    _loading = true;
    try {
      await _refreshDetected();
      await _resolveSelection();
    } finally {
      _loading = false;
    }
  }

  /// Re-probes the host without changing the user's radio choice.
  Future<void> refresh() async {
    _loading = true;
    try {
      await _refreshDetected();
      final choice = _selected;
      if (choice != null) {
        _selectionApplied = _matchesDetected(choice);
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> _refreshDetected() async {
    final result = await _probe.detect();
    _detected = result.preference;
    _statusDetail = result.detail;
  }

  Future<void> _resolveSelection() async {
    final saved = _readSavedSelection != null
        ? await _readSavedSelection!()
        : null;

    if (saved != null && saved.isSelectable) {
      _selected = saved.normalizedSelection;
    } else {
      _selected = _detected.normalizedSelection;
    }

    _selectionApplied = _matchesDetected(_selected!);
  }

  void select(Ipv6Preference preference) {
    if (!preference.isSelectable || _applying) return;
    _selectionApplied = false;
    _selected = preference.normalizedSelection;
    final save = _saveSelection;
    if (save != null) {
      unawaited(save(preference));
    }
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

    final choice = _selected?.normalizedSelection;
    if (choice == null) {
      return FixResult.failure(
        FixActionKind.disableIpv6,
        message: 'Choose a preference first.',
        executed: false,
        platform: _autoFix.platform,
      );
    }

    _applying = true;
    try {
      final FixResult result;
      if (choice == Ipv6Preference.automatic) {
        result = await _autoFix.restoreDefault(onPhase: onPhase);
      } else if (choice == Ipv6Preference.preferIpv4) {
        result = await _autoFix.apply(
          FixType.preferIpv4,
          onPhase: onPhase,
        );
      } else {
        result = FixResult.failure(
          FixActionKind.disableIpv6,
          message: 'Choose a preference first.',
          executed: false,
          platform: _autoFix.platform,
        );
      }

      if (result.success) {
        await load();
        _selected = choice.normalizedSelection;
        _selectionApplied = true;
        final save = _saveSelection;
        if (save != null) {
          await save(choice.normalizedSelection);
        }
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
        await load();
        _selected = Ipv6Preference.automatic;
        _selectionApplied = true;
        final save = _saveSelection;
        if (save != null) {
          await save(Ipv6Preference.automatic);
        }
      }
      return result;
    } finally {
      _applying = false;
    }
  }

  bool _matchesDetected(Ipv6Preference choice) {
    if (choice == _detected) return true;
    if (_isPreferIpv4Family(choice) && _isPreferIpv4Family(_detected)) {
      return true;
    }
    return false;
  }

  static bool _isPreferIpv4Family(Ipv6Preference preference) =>
      preference == Ipv6Preference.preferIpv4 ||
      preference == Ipv6Preference.disableIpv6;
}
