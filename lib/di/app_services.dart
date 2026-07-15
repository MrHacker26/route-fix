import '../application/diagnostics/diagnostics_coordinator.dart';
import '../data/services/cloudflare/dart_io_cloudflare_diagnostics_service.dart';
import '../data/services/dns/dart_io_dns_lookup_service.dart';
import '../data/services/github/dart_io_github_diagnostics_service.dart';
import '../data/services/ipv4/dart_io_ipv4_connectivity_service.dart';
import '../data/services/ipv6/dart_io_ipv6_connectivity_service.dart';
import '../data/services/pypi/dart_io_pypi_diagnostics_service.dart';
import '../domain/diagnosis/engine/diagnosis_engine.dart';

/// Composition root for RouteFix runtime dependencies.
abstract final class AppServices {
  static DiagnosticsCoordinator? _diagnostics;

  static DiagnosticsCoordinator get diagnostics {
    return _diagnostics ??= DefaultDiagnosticsCoordinator(
      dnsLookup: const DartIoDnsLookupService(),
      ipv4Connectivity: const DartIoIpv4ConnectivityService(),
      ipv6Connectivity: const DartIoIpv6ConnectivityService(),
      githubDiagnostics: DartIoGithubDiagnosticsService(),
      cloudflareDiagnostics: DartIoCloudflareDiagnosticsService(),
      pypiDiagnostics: DartIoPypiDiagnosticsService(),
      engine: DiagnosisEngine(),
    );
  }

  /// Test / preview override.
  static set diagnostics(DiagnosticsCoordinator coordinator) {
    _diagnostics = coordinator;
  }

  static void reset() {
    _diagnostics = null;
  }
}
