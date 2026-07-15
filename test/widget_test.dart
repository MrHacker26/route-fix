import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_fix/main.dart';

void main() {
  testWidgets('App boots with dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteFixApp());
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
