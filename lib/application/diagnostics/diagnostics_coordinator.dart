import '../../domain/diagnosis/engine/diagnosis_engine.dart';
import '../../domain/diagnosis/engine/diagnosis_observations.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import '../../domain/models/http_probe_result.dart';
import '../../domain/models/ipv4_connectivity_result.dart';
import '../../domain/models/ipv6_connectivity_result.dart';
import '../../domain/services/cloudflare_diagnostics_service.dart';
import '../../domain/services/dns_lookup_service.dart';
import '../../domain/services/github_diagnostics_service.dart';
import '../../domain/services/ipv4_connectivity_service.dart';
import '../../domain/services/ipv6_connectivity_service.dart';
import '../../domain/services/pypi_diagnostics_service.dart';

/// Orchestrates diagnostic services and hands outputs to [DiagnosisEngine].
///
/// No scoring / rule logic lives here — only sequencing and wiring.
abstract interface class DiagnosticsCoordinator {
  /// Runs all diagnostic services for [hostname], then builds a report.
  Future<DiagnosticReport> run({String hostname = 'www.cloudflare.com'});
}

/// Default coordinator — parallel service calls, then engine.analyze.
final class DefaultDiagnosticsCoordinator implements DiagnosticsCoordinator {
  DefaultDiagnosticsCoordinator({
    required this.dnsLookup,
    required this.ipv4Connectivity,
    required this.ipv6Connectivity,
    required this.githubDiagnostics,
    required this.cloudflareDiagnostics,
    required this.pypiDiagnostics,
    required this.engine,
  });

  final DnsLookupService dnsLookup;
  final Ipv4ConnectivityService ipv4Connectivity;
  final Ipv6ConnectivityService ipv6Connectivity;
  final GithubDiagnosticsService githubDiagnostics;
  final CloudflareDiagnosticsService cloudflareDiagnostics;
  final PypiDiagnosticsService pypiDiagnostics;
  final DiagnosisEngine engine;

  @override
  Future<DiagnosticReport> run({
    String hostname = 'www.cloudflare.com',
  }) async {
    final host =
        hostname.trim().isEmpty ? 'www.cloudflare.com' : hostname.trim();

    final dnsFuture = dnsLookup.lookup(host);
    final ipv4Future = ipv4Connectivity.check(host);
    final ipv6Future = ipv6Connectivity.check(host);
    final githubFuture = githubDiagnostics.check();
    final cloudflareFuture = cloudflareDiagnostics.check();
    final pypiFuture = pypiDiagnostics.check();

    final dnsResult = await dnsFuture;
    final ipv4 = await ipv4Future;
    final ipv6 = await ipv6Future;
    final github = await githubFuture;
    final cloudflare = await cloudflareFuture;
    final pypi = await pypiFuture;

    final report = engine.analyze(
      DiagnosisObservations(
        dnsLookup: dnsResult,
        ipv4Connectivity: ipv4,
        ipv6Connectivity: ipv6,
        githubProbe: github,
        pypiDiagnostics: pypi,
      ),
    );

    return DiagnosticReport(
      id: report.id,
      createdAt: report.createdAt,
      health: report.health,
      confidence: report.confidence,
      issues: report.issues,
      recommendations: report.recommendations,
      duration: report.duration,
      metadata: {
        ...report.metadata,
        ..._serviceMetadata(
          hostname: host,
          ipv4: ipv4,
          ipv6: ipv6,
          cloudflare: cloudflare,
        ),
      },
    );
  }

  Map<String, String> _serviceMetadata({
    required String hostname,
    required Ipv4ConnectivityResult ipv4,
    required Ipv6ConnectivityResult ipv6,
    required HttpProbeResult cloudflare,
  }) {
    return {
      'target_hostname': hostname,
      'ipv4_success': '${ipv4.success}',
      if (ipv4.latency != null)
        'ipv4_latency_ms': '${ipv4.latency!.inMilliseconds}',
      if (ipv4.resolvedAddress != null) 'ipv4_address': ipv4.resolvedAddress!,
      if (ipv4.error != null) 'ipv4_error': ipv4.error!,
      'ipv6_success': '${ipv6.success}',
      if (ipv6.latency != null)
        'ipv6_latency_ms': '${ipv6.latency!.inMilliseconds}',
      if (ipv6.resolvedAddress != null) 'ipv6_address': ipv6.resolvedAddress!,
      if (ipv6.error != null) 'ipv6_error': ipv6.error!,
      'cloudflare_success': '${cloudflare.success}',
      if (cloudflare.latency != null)
        'cloudflare_latency_ms': '${cloudflare.latency!.inMilliseconds}',
      if (cloudflare.httpStatus != null)
        'cloudflare_http_status': '${cloudflare.httpStatus}',
      if (cloudflare.error != null) 'cloudflare_error': cloudflare.error!,
    };
  }
}
