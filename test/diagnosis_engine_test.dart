import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/abstractions/result.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/domain/diagnosis/diagnosis.dart';
import 'package:route_fix/domain/models/dns_lookup_result.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/models/ipv6_connectivity_result.dart';
import 'package:route_fix/domain/models/pypi_diagnostics_result.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 7, 15, 14, 30);

  DiagnosisEngine engine() {
    return DiagnosisEngine(
      clock: () => fixedTime,
      reportIdFactory: () => 'report-test',
    );
  }

  DiagnosisObservations healthyObservations() {
    return const DiagnosisObservations(
      dnsLookup: Success(
        DnsLookupResult(
          hostname: 'example.com',
          ipv4Addresses: ['93.184.216.34'],
          ipv6Addresses: ['2606:2800:220:1:248:1893:25c8:1946'],
          lookupDuration: Duration(milliseconds: 12),
        ),
      ),
      ipv6Connectivity: Ipv6ConnectivityResult(
        success: true,
        latency: Duration(milliseconds: 40),
        resolvedAddress: '::1',
      ),
      githubProbe: HttpProbeResult(
        success: true,
        latency: Duration(milliseconds: 55),
        httpStatus: 200,
      ),
      pypiDiagnostics: PypiDiagnosticsResult(
        index: HostHttpProbeResult(
          hostname: 'pypi.org',
          success: true,
          latency: Duration(milliseconds: 60),
          httpStatus: 200,
        ),
        files: HostHttpProbeResult(
          hostname: 'files.pythonhosted.org',
          success: true,
          latency: Duration(milliseconds: 70),
          httpStatus: 200,
        ),
      ),
    );
  }

  test('healthy observations produce high score and no issues', () {
    final report = engine().analyze(healthyObservations());

    expect(report.id, 'report-test');
    expect(report.createdAt, fixedTime);
    expect(report.issues, isEmpty);
    expect(report.recommendations, isEmpty);
    expect(report.health.score, greaterThanOrEqualTo(90));
    expect(report.health.label, 'Excellent');
    expect(report.confidence, greaterThan(0.7));
    expect(report.metadata['rules_evaluated'], '5');
    expect(report.metadata['rules_failed'], '0');
  });

  test('failed observations produce issues, recommendations, and lower score', () {
    final report = engine().analyze(
      DiagnosisObservations(
        dnsLookup: const Failure(UnavailableFailure('DNS lookup failed')),
        ipv6Connectivity: const Ipv6ConnectivityResult(
          success: false,
          failure: DNSFailure('No IPv6 address found'),
        ),
        githubProbe: const HttpProbeResult(
          success: false,
          httpStatus: 503,
          failure: HTTPFailure('Unexpected HTTP status 503', statusCode: 503),
        ),
        pypiDiagnostics: const PypiDiagnosticsResult(
          index: HostHttpProbeResult(
            hostname: 'pypi.org',
            success: true,
            latency: Duration(milliseconds: 900),
            httpStatus: 200,
          ),
          files: HostHttpProbeResult(
            hostname: 'files.pythonhosted.org',
            success: true,
            latency: Duration(milliseconds: 80),
            httpStatus: 200,
          ),
        ),
      ),
    );

    expect(report.issues, isNotEmpty);
    expect(report.recommendations, isNotEmpty);
    expect(report.issues.length, report.recommendations.length);
    expect(report.health.score, lessThan(90));
    expect(report.confidence, greaterThan(0));
    expect(
      report.issues.map((i) => i.id),
      containsAll([
        'dns_failure',
        'ipv6_unavailable',
        'github_connectivity',
        'pypi_latency',
      ]),
    );
  });
}
