import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_fix/features/dashboard/dashboard_page.dart';
import 'package:route_fix/features/diagnostics/diagnostics_page.dart';
import 'package:route_fix/features/diagnostics/diagnostics_result_page.dart';
import 'package:route_fix/features/onboarding/onboarding_page.dart';
import 'package:route_fix/main.dart';

void main() {
  testWidgets('App opens onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteFixApp());

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Dashboard renders health report sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Health report'), findsOneWidget);
    expect(find.text('Overall health'), findsOneWidget);
    expect(find.text('Connection status'), findsOneWidget);
    expect(find.text('Quick summary'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Start Diagnosis'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent scan'), findsOneWidget);
    expect(find.text('Start Diagnosis'), findsOneWidget);
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
    expect(find.text('GitHub'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('PyPI'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cloudflare'), findsOneWidget);
    expect(find.text('PyPI'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Scanning'), findsOneWidget);
  });

  testWidgets('Results screen shows report sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiagnosticsResultPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.text('Scan results'), findsOneWidget);
    expect(find.text('Overall score'), findsOneWidget);
    expect(find.text('Latency by target'), findsOneWidget);
    expect(find.text('Health cards'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recommendations'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Detected issues'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);
  });
}
