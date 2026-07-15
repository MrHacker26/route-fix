import '../../../core/abstractions/result.dart';
import '../../models/dns_lookup_result.dart';
import '../../models/http_probe_result.dart';
import '../../models/ipv4_connectivity_result.dart';
import '../../models/ipv6_connectivity_result.dart';
import '../../models/pypi_diagnostics_result.dart';

/// Bundle of service outputs for the diagnosis engine.
///
/// Contains no networking — callers supply results already gathered.
final class DiagnosisObservations {
  const DiagnosisObservations({
    required this.dnsLookup,
    required this.ipv4Connectivity,
    required this.ipv6Connectivity,
    required this.githubProbe,
    required this.pypiDiagnostics,
  });

  final Result<DnsLookupResult> dnsLookup;
  final Ipv4ConnectivityResult ipv4Connectivity;
  final Ipv6ConnectivityResult ipv6Connectivity;
  final HttpProbeResult githubProbe;
  final PypiDiagnosticsResult pypiDiagnostics;
}

/// Dual-stack + DNS slice used by IPv6 Prefer/unavailable rules.
final class DualStackObservation {
  const DualStackObservation({
    required this.dnsLookup,
    required this.ipv4,
    required this.ipv6,
  });

  final Result<DnsLookupResult> dnsLookup;
  final Ipv4ConnectivityResult ipv4;
  final Ipv6ConnectivityResult ipv6;

  factory DualStackObservation.from(DiagnosisObservations observations) {
    return DualStackObservation(
      dnsLookup: observations.dnsLookup,
      ipv4: observations.ipv4Connectivity,
      ipv6: observations.ipv6Connectivity,
    );
  }
}
