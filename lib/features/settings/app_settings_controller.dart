import 'package:flutter/material.dart';

import '../../core/abstractions/result.dart';
import '../../data/settings/json_file_settings_repository.dart';
import '../../domain/repositories/settings_repository.dart';

/// Live preferences for the RouteFix UI and diagnostics.
final class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    SettingsRepository? repository,
  }) : _repository = repository ?? JsonFileSettingsRepository();

  final SettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  var _loaded = false;
  var _saving = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;
  bool get isSaving => _saving;

  ThemeMode get themeMode => switch (_settings.appearance) {
        AppAppearance.dark => ThemeMode.dark,
        AppAppearance.system => ThemeMode.system,
      };

  Future<void> load() async {
    final result = await _repository.getSettings();
    _settings = switch (result) {
      Success(:final value) => value,
      Failure() => const AppSettings(),
    };
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings current) build) async {
    final next = build(_settings);
    _settings = next;
    notifyListeners();
    _saving = true;
    await _repository.saveSettings(_settings);
    _saving = false;
    notifyListeners();
  }

  Future<void> setAppearance(AppAppearance appearance) {
    return update((current) => current.copyWith(appearance: appearance));
  }

  Future<void> setDiagnosticsTimeoutSeconds(int seconds) {
    return update(
      (current) => current.copyWith(
        diagnosticsTimeoutSeconds: seconds.clamp(5, 30),
      ),
    );
  }

  Future<void> setAutoRerunAfterFixes(bool value) {
    return update((current) => current.copyWith(autoRerunAfterFixes: value));
  }

  Future<void> setShowTechnicalDetailsByDefault(bool value) {
    return update(
      (current) => current.copyWith(showTechnicalDetailsByDefault: value),
    );
  }

  Future<void> setNetworkControlsIpv6Preference(String preferenceName) {
    return update(
      (current) => current.copyWith(
        networkControlsIpv6Preference: preferenceName,
      ),
    );
  }
}
