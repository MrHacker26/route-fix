import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_fix/features/dashboard/dashboard_page.dart';
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
}
