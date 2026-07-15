import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/abstractions/result.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/domain/diagnosis/diagnosis.dart';
import 'package:route_fix/domain/models/dns_lookup_result.dart';
import 'package:route_fix/domain/models/http_probe_result.dart';
import 'package:route_fix/domain/models/ipv6_connectivity_result.dart';
import 'package:route_fix/domain/models/pypi_diagnostics_result.dart';

void main() {
  group('Ipv6LatencyRule', () {
    const rule = Ipv6LatencyRule(threshold: Duration(milliseconds: 100));

    test('fails when latency exceeds threshold', () {
      final result = rule.evaluate(
        const Ipv6ConnectivityResult(
          success: true,
          latency: Duration(milliseconds: 250),
          resolvedAddress: '::1',
        ),
      );

      expect(result.failed, isTrue);
      expect(result.passed, isFalse);
      expect(result.recommendation, isNotNull);
      expect(result.confidence, greaterThan(0.5));
    });

    test('passes when latency is within threshold', () {
      final result = rule.evaluate(
        const Ipv6ConnectivityResult(
          success: true,
          latency: Duration(milliseconds: 40),
          resolvedAddress: '::1',
        ),
      );

      expect(result.passed, isTrue);
      expect(result.failed, isFalse);
    });
  });

  group('Ipv6UnavailableRule', () {
    const rule = Ipv6UnavailableRule();

    test('fails when IPv6 is unavailable', () {
      final result = rule.evaluate(
        const Ipv6ConnectivityResult(
          success: false,
          error: 'No IPv6 address found',
        ),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation?.id, 'ipv6-unavailable');
    });
  });

  group('DnsFailureRule', () {
    const rule = DnsFailureRule();

    test('fails on lookup failure', () {
      final result = rule.evaluate(
        const Failure(UnavailableFailure('DNS lookup failed')),
      );

      expect(result.failed, isTrue);
      expect(result.recommendation, isNotNull);
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

    test('fails when GitHub probe is unsuccessful', () {
      final result = rule.evaluate(
        const HttpProbeResult(
          success: false,
          httpStatus: 503,
          error: 'Unexpected HTTP status 503',
        ),
      );

      expect(result.failed, isTrue);
      expect(result.passed, isFalse);
      expect(result.recommendation, isNotNull);
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
}
