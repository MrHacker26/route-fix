import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/app_info.dart';
import 'package:route_fix/design_system/design_system.dart';
import 'package:route_fix/features/about/about_dialog.dart';

void main() {
  testWidgets('About dialog shows product metadata', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SecondaryButton(
                label: 'Open',
                onPressed: () => showAboutRouteFixDialog(context),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.text(AppInfo.versionLabel), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Platform'), findsOneWidget);
    expect(find.text(AppInfo.platformLabel), findsOneWidget);
    expect(find.text(AppInfo.license), findsOneWidget);
    expect(find.text(AppInfo.githubLabel), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
