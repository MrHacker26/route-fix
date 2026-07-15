import '../application/diagnostics/diagnostics_coordinator.dart';
import '../data/autofix/adapters/auto_fix_provider_adapter.dart';
import '../data/autofix/platform_fix_provider_factory.dart';
import '../data/services/cloudflare/dart_io_cloudflare_diagnostics_service.dart';
import '../data/services/dns/dart_io_dns_lookup_service.dart';
import '../data/services/github/dart_io_github_diagnostics_service.dart';
import '../data/services/ipv4/dart_io_ipv4_connectivity_service.dart';
import '../data/services/ipv6/dart_io_ipv6_connectivity_service.dart';
import '../data/services/pypi/dart_io_pypi_diagnostics_service.dart';
import '../domain/autofix/auto_fix_service.dart';
import '../domain/autofix/fix_provider.dart';
import '../domain/diagnosis/engine/diagnosis_engine.dart';
import '../features/settings/app_settings_controller.dart';

/// Composition root for RouteFix runtime dependencies.
abstract final class AppServices {
  static DiagnosticsCoordinator? _diagnostics;
  static FixProvider? _fixProvider;
  static AutoFixService? _autoFix;
  static AppSettingsController? _settings;
  static Duration? _diagnosticsTimeout;

  static AppSettingsController get settings {
    return _settings ??= AppSettingsController();
  }

  static DiagnosticsCoordinator get diagnostics {
    final timeout = settings.settings.diagnosticsTimeout;
    if (_diagnostics == null || _diagnosticsTimeout != timeout) {
      _diagnosticsTimeout = timeout;
      _diagnostics = _buildDiagnostics(timeout);
    }
    return _diagnostics!;
  }

  static DiagnosticsCoordinator _buildDiagnostics(Duration timeout) {
    return DefaultDiagnosticsCoordinator(
      dnsLookup: DartIoDnsLookupService(timeout: timeout),
      ipv4Connectivity: DartIoIpv4ConnectivityService(timeout: timeout),
      ipv6Connectivity: DartIoIpv6ConnectivityService(timeout: timeout),
      githubDiagnostics: DartIoGithubDiagnosticsService(timeout: timeout),
      cloudflareDiagnostics:
          DartIoCloudflareDiagnosticsService(timeout: timeout),
      pypiDiagnostics: DartIoPypiDiagnosticsService(timeout: timeout),
      engine: DiagnosisEngine(),
    );
  }

  /// Production Auto Fix orchestration (apply / restore).
  static AutoFixService get autoFix {
    return _autoFix ??= createAutoFixService();
  }

  /// Catalog bridge for recommendations — shares [autoFix] for apply.
  static FixProvider get fixProvider {
    return _fixProvider ??= AutoFixProviderAdapter(service: autoFix);
  }

  /// Test / preview override.
  static set diagnostics(DiagnosticsCoordinator coordinator) {
    _diagnostics = coordinator;
    _diagnosticsTimeout = null;
  }

  /// Test / preview override.
  static set fixProvider(FixProvider provider) {
    _fixProvider = provider;
  }

  /// Test / preview override.
  static set autoFix(AutoFixService service) {
    _autoFix = service;
    _fixProvider = AutoFixProviderAdapter(service: service);
  }

  /// Test / preview override.
  static set settings(AppSettingsController controller) {
    _settings = controller;
  }

  /// Rebuild diagnostics using the latest timeout preference.
  static void invalidateDiagnostics() {
    _diagnostics = null;
    _diagnosticsTimeout = null;
  }

  static void reset() {
    _diagnostics = null;
    _diagnosticsTimeout = null;
    _fixProvider = null;
    _autoFix = null;
    _settings = null;
  }
}
