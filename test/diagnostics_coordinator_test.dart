import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/application/diagnostics/diagnostics_coordinator.dart';
import 'package:route_fix/core/abstractions/result.dart';
import 'package:route_fix/domain/diagnosis/diagnosis.dart';
import 'package:route_fix/domain/models/dns_lookup_result.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/models/ipv4_connectivity_result.dart';
import 'package:route_fix/domain/models/ipv6_connectivity_result.dart';
import 'package:route_fix/domain/models/pypi_diagnostics_result.dart';
import 'package:route_fix/domain/services/cloudflare_diagnostics_service.dart';
import 'package:route_fix/domain/services/dns_lookup_service.dart';
import 'package:route_fix/domain/services/github_diagnostics_service.dart';
import 'package:route_fix/domain/services/ipv4_connectivity_service.dart';
import 'package:route_fix/domain/services/ipv6_connectivity_service.dart';
import 'package:route_fix/domain/services/pypi_diagnostics_service.dart';

void main() {
  test('runs all services and returns an engine DiagnosticReport', () async {
    final dns = _FakeDns();
    final ipv4 = _FakeIpv4();
    final ipv6 = _FakeIpv6();
    final github = _FakeGithub();
    final cloudflare = _FakeCloudflare();
    final pypi = _FakePypi();

    final coordinator = DefaultDiagnosticsCoordinator(
      dnsLookup: dns,
      ipv4Connectivity: ipv4,
      ipv6Connectivity: ipv6,
      githubDiagnostics: github,
      cloudflareDiagnostics: cloudflare,
      pypiDiagnostics: pypi,
      engine: DiagnosisEngine(
        clock: () => DateTime.utc(2026, 7, 15),
        reportIdFactory: () => 'coord-report',
      ),
    );

    final report = await coordinator.run(hostname: 'example.com');

    expect(dns.calls, ['example.com']);
    expect(ipv4.calls, ['example.com']);
    expect(ipv6.calls, ['example.com']);
    expect(github.called, isTrue);
    expect(cloudflare.called, isTrue);
    expect(pypi.called, isTrue);

    expect(report.id, 'coord-report');
    expect(report.issues, isEmpty);
    expect(report.health.score, greaterThanOrEqualTo(90));
    expect(report.metadata['target_hostname'], 'example.com');
    expect(report.metadata['ipv4_success'], 'true');
    expect(report.metadata['ipv4_latency_ms'], '10');
    expect(report.metadata['ipv6_success'], 'true');
    expect(report.metadata['ipv6_latency_ms'], '12');
    expect(report.metadata['cloudflare_success'], 'true');
  });
}

class _FakeDns implements DnsLookupService {
  final calls = <String>[];

  @override
  Future<Result<DnsLookupResult>> lookup(String hostname) async {
    calls.add(hostname);
    return Success(
      DnsLookupResult(
        hostname: hostname,
        ipv4Addresses: const ['1.2.3.4'],
        ipv6Addresses: const ['2001:db8::1'],
        lookupDuration: const Duration(milliseconds: 5),
      ),
    );
  }
}

class _FakeIpv4 implements Ipv4ConnectivityService {
  final calls = <String>[];

  @override
  Future<Ipv4ConnectivityResult> check(String hostname, {int port = 443}) async {
    calls.add(hostname);
    return const Ipv4ConnectivityResult(
      success: true,
      latency: Duration(milliseconds: 10),
      resolvedAddress: '1.2.3.4',
    );
  }
}

class _FakeIpv6 implements Ipv6ConnectivityService {
  final calls = <String>[];

  @override
  Future<Ipv6ConnectivityResult> check(String hostname, {int port = 443}) async {
    calls.add(hostname);
    return const Ipv6ConnectivityResult(
      success: true,
      latency: Duration(milliseconds: 12),
      resolvedAddress: '2001:db8::1',
    );
  }
}

class _FakeGithub implements GithubDiagnosticsService {
  var called = false;

  @override
  Future<HttpProbeResult> check() async {
    called = true;
    return const HttpProbeResult(
      success: true,
      latency: Duration(milliseconds: 20),
      httpStatus: 200,
    );
  }
}

class _FakeCloudflare implements CloudflareDiagnosticsService {
  var called = false;

  @override
  Future<HttpProbeResult> check() async {
    called = true;
    return const HttpProbeResult(
      success: true,
      latency: Duration(milliseconds: 15),
      httpStatus: 200,
    );
  }
}

class _FakePypi implements PypiDiagnosticsService {
  var called = false;

  @override
  Future<PypiDiagnosticsResult> check() async {
    called = true;
    return const PypiDiagnosticsResult(
      index: HostHttpProbeResult(
        hostname: 'pypi.org',
        success: true,
        latency: Duration(milliseconds: 30),
        httpStatus: 200,
      ),
      files: HostHttpProbeResult(
        hostname: 'files.pythonhosted.org',
        success: true,
        latency: Duration(milliseconds: 35),
        httpStatus: 200,
      ),
    );
  }
}
