import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/abstractions/result.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/domain/diagnosis/diagnosis.dart';
import 'package:route_fix/domain/models/dns_lookup_result.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/models/ipv4_connectivity_result.dart';
import 'package:route_fix/domain/models/ipv6_connectivity_result.dart';
import 'package:route_fix/domain/models/probe_stage.dart';
import 'package:route_fix/domain/models/pypi_diagnostics_result.dart';

void main() {
  group('Ipv6LatencyRule', () {
    const rule = Ipv6LatencyRule(threshold: Duration(milliseconds: 100));

    DualStackObservation dual({
      required Ipv4ConnectivityResult ipv4,
      required Ipv6ConnectivityResult ipv6,
      Result<DnsLookupResult>? dns,
    }) {
      return DualStackObservation(
        dnsLookup: dns ??
            const Success(
              DnsLookupResult(
                hostname: 'example.com',
                ipv4Addresses: ['1.2.3.4'],
                ipv6Addresses: ['2001:db8::1'],
                lookupDuration: Duration(milliseconds: 5),
              ),
            ),
        ipv4: ipv4,
        ipv6: ipv6,
      );
    }

    test('recommends Prefer IPv4 when IPv6 is significantly slower', () {
      final result = rule.evaluate(
        dual(
          ipv4: const Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 20),
            resolvedAddress: '1.2.3.4',
            stageReached: ProbeStage.tcp,
          ),
          ipv6: const Ipv6ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 250),
            resolvedAddress: '::1',
            stageReached: ProbeStage.tcp,
          ),
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNotNull);
      expect(result.recommendation?.actionLabel, 'Prefer IPv4');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('passes when latency contrast is weak', () {
      final result = rule.evaluate(
        dual(
          ipv4: const Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 40),
            resolvedAddress: '1.2.3.4',
          ),
          ipv6: const Ipv6ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 50),
            resolvedAddress: '::1',
          ),
        ),
      );

      expect(result.passed, isTrue);
      expect(result.recommendation, isNull);
    });

    test('recommends Prefer IPv4 when IPv6 fails and IPv4/DNS succeed', () {
      final result = rule.evaluate(
        dual(
          ipv4: const Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 18),
            resolvedAddress: '1.2.3.4',
            stageReached: ProbeStage.tcp,
          ),
          ipv6: const Ipv6ConnectivityResult(
            success: false,
            failure: TCPFailure('Connection refused'),
            stageReached: ProbeStage.dns,
            stageFailed: ProbeStage.tcp,
          ),
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation?.metadata['fix_kind'], 'disable_ipv6');
    });

    test('does not recommend Prefer IPv4 from a generic IPv6 failure', () {
      final result = rule.evaluate(
        dual(
          ipv4: const Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 18),
            resolvedAddress: '1.2.3.4',
          ),
          ipv6: const Ipv6ConnectivityResult(
            success: false,
            failure: UnknownFailure('something went wrong'),
          ),
        ),
      );

      expect(result.passed, isTrue);
      expect(result.recommendation, isNull);
    });

    test('does not recommend Prefer IPv4 when IPv4 also failed', () {
      final result = rule.evaluate(
        dual(
          ipv4: const Ipv4ConnectivityResult(
            success: false,
            failure: TCPFailure('Connection refused'),
            stageFailed: ProbeStage.tcp,
          ),
          ipv6: const Ipv6ConnectivityResult(
            success: false,
            failure: TCPFailure('Connection refused'),
            stageFailed: ProbeStage.tcp,
          ),
        ),
      );

      expect(result.passed, isTrue);
    });

    test('does not recommend Prefer IPv4 when DNS failed', () {
      final result = rule.evaluate(
        dual(
          dns: const Failure(DNSFailure('DNS lookup failed')),
          ipv4: const Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 18),
            resolvedAddress: '1.2.3.4',
          ),
          ipv6: const Ipv6ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 400),
            resolvedAddress: '::1',
          ),
        ),
      );

      expect(result.passed, isTrue);
    });
  });

  group('Ipv6UnavailableRule', () {
    const rule = Ipv6UnavailableRule();

    test('passes when IPv6 is available', () {
      final result = rule.evaluate(
        const DualStackObservation(
          dnsLookup: Success(
            DnsLookupResult(
              hostname: 'example.com',
              ipv4Addresses: ['1.2.3.4'],
              ipv6Addresses: ['2001:db8::1'],
              lookupDuration: Duration(milliseconds: 5),
            ),
          ),
          ipv4: Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 10),
            resolvedAddress: '1.2.3.4',
          ),
          ipv6: Ipv6ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 12),
            resolvedAddress: '::1',
          ),
        ),
      );

      expect(result.passed, isTrue);
    });

    test('does not recommend Enable when IPv6 is simply unavailable', () {
      final result = rule.evaluate(
        const DualStackObservation(
          dnsLookup: Success(
            DnsLookupResult(
              hostname: 'example.com',
              ipv4Addresses: ['1.2.3.4'],
              ipv6Addresses: [],
              lookupDuration: Duration(milliseconds: 5),
            ),
          ),
          ipv4: Ipv4ConnectivityResult(
            success: true,
            latency: Duration(milliseconds: 10),
            resolvedAddress: '1.2.3.4',
          ),
          ipv6: Ipv6ConnectivityResult(
            success: false,
            failure: DNSFailure('No IPv6 address found'),
            stageFailed: ProbeStage.dns,
          ),
        ),
      );

      expect(result.passed, isTrue);
      expect(result.recommendation, isNull);
    });
  });

  group('DnsFailureRule', () {
    const rule = DnsFailureRule();

    test('recommends on typed DNS failure', () {
      final result = rule.evaluate(
        const Failure(DNSFailure('DNS lookup failed')),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNotNull);
    });

    test('does not recommend on generic failure', () {
      final result = rule.evaluate(
        const Failure(UnknownFailure('boom')),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNull);
    });

    test('passes on successful lookup', () {
      final result = rule.evaluate(
        const Success(
          DnsLookupResult(
            hostname: 'example.com',
            ipv4Addresses: ['93.184.216.34'],
            ipv6Addresses: [],
            lookupDuration: Duration(milliseconds: 12),
          ),
        ),
      );

      expect(result.passed, isTrue);
    });
  });

  group('PyPILatencyRule', () {
    const rule = PyPILatencyRule(threshold: Duration(milliseconds: 100));

    test('fails when a PyPI host is slow', () {
      final result = rule.evaluate(
        const PypiDiagnosticsResult(
          index: HostHttpProbeResult(
            hostname: 'pypi.org',
            success: true,
            latency: Duration(milliseconds: 50),
            httpStatus: 200,
          ),
          files: HostHttpProbeResult(
            hostname: 'files.pythonhosted.org',
            success: true,
            latency: Duration(milliseconds: 500),
            httpStatus: 200,
          ),
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation?.detail, contains('files.pythonhosted.org'));
    });
  });

  group('GitHubConnectivityRule', () {
    const rule = GitHubConnectivityRule();

    test('recommends on typed HTTP failure', () {
      final result = rule.evaluate(
        const HttpProbeResult(
          success: false,
          httpStatus: 503,
          stageReached: ProbeStage.http,
          stageFailed: ProbeStage.http,
          failure: HTTPFailure('Unexpected HTTP status 503', statusCode: 503),
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNotNull);
    });

    test('does not recommend on generic failure', () {
      final result = rule.evaluate(
        const HttpProbeResult(
          success: false,
          failure: UnknownFailure('Connection failed'),
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNull);
    });

    test('does not recommend from a DNS-stage GitHub miss', () {
      final result = rule.evaluate(
        const HttpProbeResult(
          success: false,
          stageFailed: ProbeStage.dns,
          failure: DNSFailure('Failed host lookup'),
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNull);
    });

    test('passes when GitHub probe succeeds', () {
      final result = rule.evaluate(
        const HttpProbeResult(
          success: true,
          latency: Duration(milliseconds: 18),
          httpStatus: 200,
        ),
      );

      expect(result.passed, isTrue);
      expect(result.failed, isFalse);
    });
  });

  group('DiagnosisEvidence', () {
    test('requires high confidence floor', () {
      expect(DiagnosisEvidence.isHighConfidence(0.84), isFalse);
      expect(DiagnosisEvidence.isHighConfidence(0.85), isTrue);
    });
  });
}
