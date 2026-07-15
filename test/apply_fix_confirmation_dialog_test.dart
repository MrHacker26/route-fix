import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/design_system/design_system.dart';
import 'package:route_fix/features/diagnostics/apply_fix_confirmation_dialog.dart';
import 'package:route_fix/features/diagnostics/diagnostics_result_view_data.dart';
import 'package:route_fix/features/diagnostics/recommended_fix_card.dart';

void main() {
  const fix = RecommendedFixView(
    id: 'disableIpv6',
    title: 'Disable IPv6',
    description: 'Prefer IPv4 when IPv6 paths are pathological.',
    availabilityLabel: 'Ready',
    availabilityTone: StatusBadgeTone.success,
    icon: Icons.settings_ethernet_rounded,
    canConfirmApply: true,
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    );
  }

  testWidgets('Apply Fix opens confirmation dialog without executing',
      (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          onConfirmed: (_) => confirmed = true,
        ),
      ),
    );

    await tester.tap(find.text('Apply Fix'));
    await tester.pumpAndSettle();

    expect(find.text('Apply Fix?'), findsOneWidget);
    expect(find.text('Disable IPv6'), findsWidgets);
    expect(find.text('Confirm'), findsOneWidget);
    expect(confirmed, isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Apply Fix?'), findsNothing);
    expect(confirmed, isFalse);
  });

  testWidgets('Confirm returns confirmed intent only', (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          onConfirmed: (_) => confirmed = true,
        ),
      ),
    );

    await tester.tap(find.text('Apply Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Apply Fix?'), findsNothing);
  });

  testWidgets('showApplyFixConfirmation reports cancel by default',
      (tester) async {
    late ApplyFixConfirmationResult result;

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return PrimaryButton(
              label: 'Open',
              onPressed: () async {
                result = await showApplyFixConfirmation(context, fix: fix);
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, ApplyFixConfirmationResult.cancelled);
  });
}
