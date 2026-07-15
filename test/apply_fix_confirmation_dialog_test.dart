import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/design_system/design_system.dart';
import 'package:route_fix/domain/autofix/autofix.dart';
import 'package:route_fix/features/diagnostics/apply_fix_confirmation_dialog.dart';
import 'package:route_fix/features/diagnostics/diagnostics_result_view_data.dart';
import 'package:route_fix/features/diagnostics/recommended_fix_card.dart';

void main() {
  const fix = RecommendedFixView(
    id: 'disableIpv6',
    kind: FixActionKind.disableIpv6,
    title: 'Disable IPv6',
    description: 'Prefer IPv4 when IPv6 paths are pathological.',
    why: 'Your IPv6 latency is 18× higher than IPv4.',
    confidenceLabel: '96%',
    estimatedImprovement: 'High',
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

  testWidgets('shows trustworthy recommendation detail before apply',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          fixProvider: _FakeFixProvider(
            onApply: (_) async => FixResult.success(
              FixActionKind.disableIpv6,
              message: 'ok',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recommended Action'), findsOneWidget);
    expect(find.text('Disable IPv6'), findsOneWidget);
    expect(find.text('Why?'), findsOneWidget);
    expect(
      find.text('Your IPv6 latency is 18× higher than IPv4.'),
      findsOneWidget,
    );
    expect(find.text('Confidence'), findsOneWidget);
    expect(find.text('96%'), findsOneWidget);
    expect(find.text('Estimated Improvement'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Apply Recommended Fix'), findsOneWidget);
  });

  testWidgets('Apply Recommended Fix confirms then shows success UX',
      (tester) async {
    final provider = _FakeFixProvider(
      onApply: (_) async => FixResult.success(
        FixActionKind.disableIpv6,
        message: 'IPv6 disabled.',
      ),
    );
    var rerun = false;

    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          fixProvider: provider,
          onRerunDiagnostics: () => rerun = true,
        ),
      ),
    );

    await tester.tap(find.text('Apply Recommended Fix'));
    await tester.pumpAndSettle();
    expect(find.text('Apply Fix?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(provider.applyCalls, [FixActionKind.disableIpv6]);
    expect(find.text('Fix Applied'), findsOneWidget);
    expect(
      find.textContaining('Please run diagnostics again'),
      findsOneWidget,
    );
    expect(find.text('Re-run Diagnostics'), findsOneWidget);

    await tester.tap(find.text('Re-run Diagnostics'));
    await tester.pump();
    expect(rerun, isTrue);
  });

  testWidgets('shows failure message and keeps apply available', (tester) async {
    final completer = Completer<FixResult>();
    final provider = _FakeFixProvider(onApply: (_) => completer.future);

    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          fixProvider: provider,
        ),
      ),
    );

    await tester.tap(find.text('Apply Recommended Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Applying…'), findsOneWidget);

    completer.complete(
      FixResult.failure(
        FixActionKind.disableIpv6,
        message: 'Failed to disable IPv6.',
        error: 'permission denied',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('permission denied'), findsOneWidget);
    expect(find.text('Apply Recommended Fix'), findsOneWidget);
  });

  testWidgets('cancel does not call provider', (tester) async {
    final provider = _FakeFixProvider(
      onApply: (_) async => FixResult.success(
        FixActionKind.disableIpv6,
        message: 'ok',
      ),
    );

    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          fixProvider: provider,
        ),
      ),
    );

    await tester.tap(find.text('Apply Recommended Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(provider.applyCalls, isEmpty);
    expect(find.text('Apply Recommended Fix'), findsOneWidget);
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

final class _FakeFixProvider implements FixProvider {
  _FakeFixProvider({required this.onApply});

  final Future<FixResult> Function(FixActionKind kind) onApply;
  final List<FixActionKind> applyCalls = [];

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  List<FixAction> availableActions() => const [];

  @override
  bool supports(FixActionKind kind) => true;

  @override
  Future<FixResult> apply(FixActionKind kind) async {
    applyCalls.add(kind);
    return onApply(kind);
  }
}
