import '../../core/abstractions/result.dart';

/// User preferences for RouteFix.
abstract interface class SettingsRepository {
  Future<Result<AppSettings>> getSettings();

  Future<Result<void>> saveSettings(AppSettings settings);
}

/// Lightweight preference snapshot.
class AppSettings {
  const AppSettings({
    this.hasCompletedOnboarding = false,
    this.diagnosticsTimeoutSeconds = 8,
    this.autoRerunAfterFixes = true,
    this.showTechnicalDetailsByDefault = false,
    this.preferredDnsHint,
    this.networkControlsIpv6Preference,
    this.networkControlsDnsPreference,
  });

  final bool hasCompletedOnboarding;
  final int diagnosticsTimeoutSeconds;

  /// Re-run diagnostics after a successful Auto Fix.
  final bool autoRerunAfterFixes;

  /// Expand Technical details sections on first open.
  final bool showTechnicalDetailsByDefault;

  final String? preferredDnsHint;

  /// Last IPv6 preference chosen in Network Controls ([Ipv6Preference.name]).
  final String? networkControlsIpv6Preference;

  /// Last DNS preference chosen in Network Controls ([DnsPreference.name]).
  final String? networkControlsDnsPreference;

  Duration get diagnosticsTimeout =>
      Duration(seconds: diagnosticsTimeoutSeconds.clamp(5, 30));

  AppSettings copyWith({
    bool? hasCompletedOnboarding,
    int? diagnosticsTimeoutSeconds,
    bool? autoRerunAfterFixes,
    bool? showTechnicalDetailsByDefault,
    String? preferredDnsHint,
    String? networkControlsIpv6Preference,
    String? networkControlsDnsPreference,
  }) {
    return AppSettings(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      diagnosticsTimeoutSeconds:
          diagnosticsTimeoutSeconds ?? this.diagnosticsTimeoutSeconds,
      autoRerunAfterFixes: autoRerunAfterFixes ?? this.autoRerunAfterFixes,
      showTechnicalDetailsByDefault:
          showTechnicalDetailsByDefault ?? this.showTechnicalDetailsByDefault,
      preferredDnsHint: preferredDnsHint ?? this.preferredDnsHint,
      networkControlsIpv6Preference:
          networkControlsIpv6Preference ?? this.networkControlsIpv6Preference,
      networkControlsDnsPreference:
          networkControlsDnsPreference ?? this.networkControlsDnsPreference,
    );
  }

  Map<String, Object?> toJson() => {
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'diagnosticsTimeoutSeconds': diagnosticsTimeoutSeconds,
        'autoRerunAfterFixes': autoRerunAfterFixes,
        'showTechnicalDetailsByDefault': showTechnicalDetailsByDefault,
        if (preferredDnsHint != null) 'preferredDnsHint': preferredDnsHint,
        if (networkControlsIpv6Preference != null)
          'networkControlsIpv6Preference': networkControlsIpv6Preference,
        if (networkControlsDnsPreference != null)
          'networkControlsDnsPreference': networkControlsDnsPreference,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final timeout = json['diagnosticsTimeoutSeconds'];
    return AppSettings(
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      diagnosticsTimeoutSeconds: timeout is int ? timeout.clamp(5, 30) : 8,
      autoRerunAfterFixes: json['autoRerunAfterFixes'] as bool? ?? true,
      showTechnicalDetailsByDefault:
          json['showTechnicalDetailsByDefault'] as bool? ?? false,
      preferredDnsHint: json['preferredDnsHint'] as String?,
      networkControlsIpv6Preference:
          json['networkControlsIpv6Preference'] as String?,
      networkControlsDnsPreference:
          json['networkControlsDnsPreference'] as String?,
    );
  }
}
