import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_fix/features/onboarding/onboarding_page.dart';
import 'package:route_fix/main.dart';

void main() {
  testWidgets('App opens onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteFixApp());

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('RouteFix'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Onboarding advances to final step', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPage(),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Not a speed test'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Find the real bottleneck'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
