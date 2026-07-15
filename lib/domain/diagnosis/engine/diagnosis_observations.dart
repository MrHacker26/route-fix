import '../../../core/abstractions/result.dart';
import '../../models/dns_lookup_result.dart';
import '../../models/http_probe_result.dart';
import '../../models/ipv6_connectivity_result.dart';
import '../../models/pypi_diagnostics_result.dart';

/// Bundle of service outputs for the diagnosis engine.
///
/// Contains no networking — callers supply results already gathered.
final class DiagnosisObservations {
  const DiagnosisObservations({
    required this.dnsLookup,
    required this.ipv6Connectivity,
    required this.githubProbe,
    required this.pypiDiagnostics,
  });

  final Result<DnsLookupResult> dnsLookup;
  final Ipv6ConnectivityResult ipv6Connectivity;
  final HttpProbeResult githubProbe;
  final PypiDiagnosticsResult pypiDiagnostics;
}
