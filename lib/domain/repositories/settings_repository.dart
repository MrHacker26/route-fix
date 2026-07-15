import '../../core/abstractions/result.dart';

/// User / app preference flags. No implementation.
abstract interface class SettingsRepository {
  Future<Result<AppSettings>> getSettings();

  Future<Result<void>> saveSettings(AppSettings settings);
}

/// Settings snapshot (domain shape only).
class AppSettings {
  const AppSettings({
    this.hasCompletedOnboarding = false,
    this.preferredDnsHint,
  });

  final bool hasCompletedOnboarding;
  final String? preferredDnsHint;
}
