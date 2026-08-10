import 'dart:async';

import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/models/fix_action.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_executor.dart';
import 'dns_preference.dart';
import 'dns_preference_probe.dart';
import 'ipv6_preference.dart';
import 'ipv6_preference_probe.dart';

/// Orchestrates Network Controls against existing Auto Fix infrastructure.
final class NetworkControlsController {
  NetworkControlsController({
    required AutoFixService autoFix,
    required Ipv6PreferenceProbe probe,
    DnsPreferenceProbe? dnsProbe,
    Future<Ipv6Preference?> Function()? readSavedIpv6Selection,
    Future<void> Function(Ipv6Preference preference)? saveIpv6Selection,
    Future<DnsPreference?> Function()? readSavedDnsSelection,
    Future<void> Function(DnsPreference preference)? saveDnsSelection,
    Future<Ipv6Preference?> Function()? readSavedSelection,
    Future<void> Function(Ipv6Preference preference)? saveSelection,
  })  : _autoFix = autoFix,
        _probe = probe,
        _dnsProbe = dnsProbe ?? DnsPreferenceProbe(autoFix: autoFix),
        _readSavedIpv6Selection =
            readSavedIpv6Selection ?? readSavedSelection,
        _saveIpv6Selection = saveIpv6Selection ?? saveSelection,
        _readSavedDnsSelection = readSavedDnsSelection,
        _saveDnsSelection = saveDnsSelection;

  final AutoFixService _autoFix;
  final Ipv6PreferenceProbe _probe;
  final DnsPreferenceProbe _dnsProbe;
  final Future<Ipv6Preference?> Function()? _readSavedIpv6Selection;
  final Future<void> Function(Ipv6Preference preference)? _saveIpv6Selection;
  final Future<DnsPreference?> Function()? _readSavedDnsSelection;
  final Future<void> Function(DnsPreference preference)? _saveDnsSelection;

  Ipv6Preference _detectedIpv6 = Ipv6Preference.unknown;
  Ipv6Preference? _selectedIpv6;
  DnsPreference _detectedDns = DnsPreference.unknown;
  DnsPreference? _selectedDns;
  String? _ipv6StatusDetail;
  String? _dnsStatusDetail;
  var _loading = false;
  var _applying = false;
  var _ipv6SelectionApplied = false;
  var _dnsSelectionApplied = false;

  Ipv6Preference get detected => _detectedIpv6;
  Ipv6Preference? get selected => _selectedIpv6;
  String? get statusDetail => _ipv6StatusDetail;

  DnsPreference get detectedDns => _detectedDns;
  DnsPreference? get selectedDns => _selectedDns;
  String? get dnsStatusDetail => _dnsStatusDetail;

  bool get isLoading => _loading;
  bool get isApplying => _applying;
  bool get isBusy => _applying || _autoFix.isBusy;

  bool get hasPendingIpv6Changes {
    if (_ipv6SelectionApplied) return false;
    final choice = _selectedIpv6;
    if (choice == null || !choice.isSelectable) return false;
    if (_detectedIpv6 == Ipv6Preference.unknown) {
      return choice != Ipv6Preference.automatic;
    }
    return !_matchesDetectedIpv6(choice);
  }

  bool get hasPendingDnsChanges {
    if (_dnsSelectionApplied) return false;
    final choice = _selectedDns;
    if (choice == null || !choice.isSelectable) return false;
    if (_detectedDns == DnsPreference.unknown) {
      return choice != DnsPreference.automatic;
    }
    return choice != _detectedDns;
  }

  bool get hasPendingChanges => hasPendingIpv6Changes || hasPendingDnsChanges;

  bool get supportsPlatform =>
      _autoFix.supports(FixType.preferIpv4) ||
      _autoFix.supports(FixType.restoreDefault);

  bool get supportsDns =>
      _autoFix.supports(FixType.changeDnsCloudflare) ||
      _autoFix.supports(FixType.restoreDns) ||
      _autoFix.supports(FixType.flushDnsCache);

  Future<void> load() async {
    _loading = true;
    try {
      await _refreshDetected();
      await _resolveSelections();
    } finally {
      _loading = false;
    }
  }

  Future<void> refresh() async {
    _loading = true;
    try {
      await _refreshDetected();
      final ipv6Choice = _selectedIpv6;
      if (ipv6Choice != null) {
        _ipv6SelectionApplied = _matchesDetectedIpv6(ipv6Choice);
      }
      final dnsChoice = _selectedDns;
      if (dnsChoice != null) {
        _dnsSelectionApplied = dnsChoice == _detectedDns;
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> _refreshDetected() async {
    final ipv6 = await _probe.detect();
    _detectedIpv6 = ipv6.preference;
    _ipv6StatusDetail = ipv6.detail;

    final dns = await _dnsProbe.detect();
    _detectedDns = dns.preference;
    _dnsStatusDetail = dns.detail;
  }

  Future<void> _resolveSelections() async {
    final readIpv6 = _readSavedIpv6Selection;
    final savedIpv6 = readIpv6 != null ? await readIpv6() : null;
    final Ipv6Preference ipv6Selected;
    if (savedIpv6 != null && savedIpv6.isSelectable) {
      ipv6Selected = savedIpv6.normalizedSelection;
    } else {
      ipv6Selected = _detectedIpv6.normalizedSelection;
    }
    _selectedIpv6 = ipv6Selected;
    _ipv6SelectionApplied = _matchesDetectedIpv6(ipv6Selected);

    final readDns = _readSavedDnsSelection;
    final savedDns = readDns != null ? await readDns() : null;
    final DnsPreference dnsSelected;
    if (savedDns != null && savedDns.isSelectable) {
      dnsSelected = savedDns.normalizedSelection;
    } else {
      dnsSelected = _detectedDns.normalizedSelection;
    }
    _selectedDns = dnsSelected;
    _dnsSelectionApplied = dnsSelected == _detectedDns;
  }

  void select(Ipv6Preference preference) {
    if (!preference.isSelectable || _applying) return;
    _ipv6SelectionApplied = false;
    _selectedIpv6 = preference.normalizedSelection;
    final save = _saveIpv6Selection;
    if (save != null) {
      unawaited(save(preference));
    }
  }

  void selectDns(DnsPreference preference) {
    if (!preference.isSelectable || _applying) return;
    _dnsSelectionApplied = false;
    _selectedDns = preference.normalizedSelection;
    final save = _saveDnsSelection;
    if (save != null) {
      unawaited(save(preference));
    }
  }

  Future<FixResult> flushDns({
    void Function(AutoFixPhase phase)? onPhase,
  }) {
    return _autoFix.apply(FixType.flushDnsCache, onPhase: onPhase);
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
      FixResult? lastResult;
      final appliedIpv6 = hasPendingIpv6Changes
          ? _selectedIpv6?.normalizedSelection
          : null;
      final appliedDns =
          hasPendingDnsChanges ? _selectedDns?.normalizedSelection : null;

      if (hasPendingIpv6Changes) {
        lastResult = await _applyIpv6(onPhase: onPhase);
        if (lastResult != null && !lastResult.success) {
          return lastResult;
        }
      }

      if (hasPendingDnsChanges) {
        lastResult = await _applyDns(onPhase: onPhase);
        if (lastResult != null && !lastResult.success) {
          return lastResult;
        }
      }

      await load();
      if (lastResult != null && lastResult.success) {
        if (appliedIpv6 != null) {
          _selectedIpv6 = appliedIpv6;
          _ipv6SelectionApplied = true;
        }
        if (appliedDns != null) {
          _selectedDns = appliedDns;
          _dnsSelectionApplied = true;
        }
      }
      return lastResult ??
          FixResult.failure(
            FixActionKind.disableIpv6,
            message: 'Nothing to apply.',
            executed: false,
            platform: _autoFix.platform,
          );
    } finally {
      _applying = false;
    }
  }

  Future<FixResult?> _applyIpv6({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    final choice = _selectedIpv6?.normalizedSelection;
    if (choice == null) return null;

    final FixResult result;
    if (choice == Ipv6Preference.automatic) {
      result = await _autoFix.restoreDefault(onPhase: onPhase);
    } else if (choice == Ipv6Preference.preferIpv4) {
      result = await _autoFix.apply(
        FixType.preferIpv4,
        onPhase: onPhase,
      );
    } else {
      return FixResult.failure(
        FixActionKind.disableIpv6,
        message: 'Choose a preference first.',
        executed: false,
        platform: _autoFix.platform,
      );
    }

    if (result.success) {
      _selectedIpv6 = choice;
      _ipv6SelectionApplied = true;
      final save = _saveIpv6Selection;
      if (save != null) {
        await save(choice);
      }
    }
    return result;
  }

  Future<FixResult?> _applyDns({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    final choice = _selectedDns?.normalizedSelection;
    if (choice == null) return null;

    final FixResult result;
    if (choice == DnsPreference.automatic) {
      final cached = _autoFix.appliedFixes
          .where((fix) => fix.type == FixType.changeDnsCloudflare)
          .toList();
      final context = cached.isNotEmpty ? cached.last.metadata : null;
      result = await _autoFix.apply(
        FixType.restoreDns,
        onPhase: onPhase,
        context: context,
      );
    } else if (choice == DnsPreference.cloudflare) {
      result = await _autoFix.apply(
        FixType.changeDnsCloudflare,
        onPhase: onPhase,
      );
    } else {
      return null;
    }

    if (result.success) {
      _selectedDns = choice;
      _dnsSelectionApplied = true;
      final save = _saveDnsSelection;
      if (save != null) {
        await save(choice);
      }
    }
    return result;
  }

  Future<FixResult> restoreDefaults({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    _applying = true;
    try {
      final result = await _autoFix.restoreDefault(onPhase: onPhase);
      if (result.success) {
        await load();
        _selectedIpv6 = Ipv6Preference.automatic;
        _selectedDns = DnsPreference.automatic;
        _ipv6SelectionApplied = true;
        _dnsSelectionApplied = true;
        final saveIpv6 = _saveIpv6Selection;
        if (saveIpv6 != null) {
          await saveIpv6(Ipv6Preference.automatic);
        }
        final saveDns = _saveDnsSelection;
        if (saveDns != null) {
          await saveDns(DnsPreference.automatic);
        }
      }
      return result;
    } finally {
      _applying = false;
    }
  }

  bool _matchesDetectedIpv6(Ipv6Preference choice) {
    if (choice == _detectedIpv6) return true;
    if (_isPreferIpv4Family(choice) && _isPreferIpv4Family(_detectedIpv6)) {
      return true;
    }
    return false;
  }

  static bool _isPreferIpv4Family(Ipv6Preference preference) =>
      preference == Ipv6Preference.preferIpv4 ||
      preference == Ipv6Preference.disableIpv6;
}
