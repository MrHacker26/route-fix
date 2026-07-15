import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_fix/application/diagnostics/diagnostics_coordinator.dart';
import 'package:route_fix/domain/models/diagnostics/diagnostics.dart';
import 'package:route_fix/features/dashboard/dashboard_page.dart';
import 'package:route_fix/features/diagnostics/diagnostics_page.dart';
import 'package:route_fix/features/diagnostics/diagnostics_result_page.dart';
import 'package:route_fix/features/onboarding/onboarding_page.dart';
import 'package:route_fix/main.dart';
import 'package:route_fix/features/settings/app_settings_controller.dart';
import 'package:route_fix/domain/repositories/settings_repository.dart';
import 'package:route_fix/core/abstractions/result.dart';

void main() {
  testWidgets('App opens onboarding', (WidgetTester tester) async {
    final settings = AppSettingsController(
      repository: _MemorySettingsRepository(),
    );
    await settings.load();
    await tester.pumpWidget(RouteFixApp(settings: settings));

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Dashboard loads as desktop command center', (
    WidgetTester tester,
  ) async {
    final coordinator = _FakeCoordinator();

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(coordinator: coordinator),
      ),
    );

    expect(find.text('Scanning your network'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('RouteFix'), findsWidgets);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recommendation'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.text('Recent scan'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Developer'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Developer services'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Technical details'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.text('All clear.'), findsOneWidget);
  });

  testWidgets('Dashboard shows retry when coordinator fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(coordinator: _FailingCoordinator()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load health report'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Diagnostics screen shows live fake targets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiagnosticsPage()),
    );
    await tester.pump();

    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('DNS'), findsOneWidget);
    expect(find.text('IPv4'), findsOneWidget);
    expect(find.text('IPv6'), findsOneWidget);
    expect(find.text('TLS'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('PyPI'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('HTTPS'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('PyPI'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Scanning'), findsOneWidget);
  });

  testWidgets('Results screen shows report sections', (WidgetTester tester) async {
    final report = DiagnosticReport(
      id: 'result-test',
      createdAt: DateTime.utc(2026, 7, 15, 12, 30),
      health: const NetworkHealth(
        score: 74,
        label: 'Fair',
        summary: 'One elevated path detected.',
        metrics: {'rules_evaluated': 5, 'rules_failed': 1},
      ),
      confidence: 0.86,
      issues: const [
        DiagnosticIssue(
          id: 'github_connectivity',
          title: 'GitHub is unreachable',
          description: 'Probe returned HTTP 503.',
          severity: DiagnosticSeverity.high,
        ),
      ],
      recommendations: const [
        Recommendation(
          id: 'github-unreachable',
          title: 'Check GitHub path',
          detail: 'Retry when GitHub status recovers.',
        ),
      ],
      metadata: const {
        'ipv4_success': 'true',
        'ipv4_latency_ms': '18',
        'ipv4_address': '1.1.1.1',
        'cloudflare_success': 'true',
        'cloudflare_latency_ms': '22',
        'cloudflare_http_status': '200',
        'rules_evaluated': '5',
        'rules_failed': '1',
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: DiagnosticsResultPage(report: report)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('Network'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('GitHub took longer than expected'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('GitHub took longer than expected'), findsOneWidget);
    expect(find.text('Impact'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('DNS · TCP · TLS · HTTP · Rules'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Technical details'), findsWidgets);
  });

  testWidgets('Results screen handles empty report calmly', (WidgetTester tester) async {
    final report = DiagnosticReport(
      id: 'empty-test',
      createdAt: DateTime.utc(2026, 7, 15, 9),
      health: const NetworkHealth(
        score: 96,
        label: 'Excellent',
        summary: 'All diagnosis rules passed.',
      ),
      confidence: 0.93,
      metadata: const {
        'ipv4_success': 'true',
        'rules_evaluated': '5',
        'rules_failed': '0',
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: DiagnosticsResultPage(report: report)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('All clear'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('All clear'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Recommendation'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No fix recommended'), findsOneWidget);
  });

  testWidgets('Results screen shows retry when load fails', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsResultPage(coordinator: _FailingCoordinator()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

class _FakeCoordinator implements DiagnosticsCoordinator {
  @override
  Future<DiagnosticReport> run({String hostname = 'www.cloudflare.com'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return DiagnosticReport(
      id: 'dash-test',
      createdAt: DateTime.utc(2026, 7, 15, 12),
      health: const NetworkHealth(
        score: 92,
        label: 'Excellent',
        summary: 'All diagnosis rules passed.',
      ),
      confidence: 0.9,
      metadata: const {
        'target_hostname': 'www.cloudflare.com',
        'dns_success': 'true',
        'dns_lookup_ms': '12',
        'ipv4_success': 'true',
        'ipv4_address': '1.1.1.1',
        'ipv4_tcp_ms': '18',
        'ipv6_success': 'false',
        'ipv6_error': 'No IPv6 address advertised by target.',
        'github_success': 'true',
        'github_http_status': '200',
        'github_http_ms': '40',
        'cloudflare_success': 'true',
        'cloudflare_http_status': '200',
        'cloudflare_http_ms': '22',
        'cloudflare_tls_ms': '15',
        'pypi_index_http_ms': '55',
        'rules_evaluated': '5',
        'rules_failed': '0',
      },
    );
  }
}

class _FailingCoordinator implements DiagnosticsCoordinator {
  @override
  Future<DiagnosticReport> run({String hostname = 'www.cloudflare.com'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    throw Exception('SocketException: Network is unreachable');
  }
}

final class _MemorySettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<Result<AppSettings>> getSettings() async => Success(_settings);

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    _settings = settings;
    return const Success(null);
  }
}
