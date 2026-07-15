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
    title: 'Prefer IPv4',
    description: 'Skip a slow IPv6 path.',
    why: 'IPv6 is responding about 18× slower than IPv4 right now.',
    whyThisRecommendation:
        'Preferring IPv4 can help apps skip a slow IPv6 path.',
    confidenceLabel: '96%',
    estimatedImprovement: 'High',
    serviceImpacts: [
      ServiceImpactView(
        name: 'Git',
        level: 'High',
        label: 'Likely improving',
        icon: Icons.merge_type_rounded,
      ),
    ],
    availabilityLabel: 'Ready',
    availabilityTone: StatusBadgeTone.success,
    icon: Icons.settings_ethernet_rounded,
    canConfirmApply: true,
    priorityScore: 30,
    backedByRuleIds: ['ipv6_latency'],
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows calm recommendation detail before apply', (tester) async {
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

    expect(find.text('Recommended action'), findsOneWidget);
    expect(find.text('Prefer IPv4'), findsOneWidget);
    expect(find.text('Why this recommendation?'), findsOneWidget);
    expect(find.text('Apply recommended fix'), findsOneWidget);
  });

  testWidgets('success shows re-run diagnostics', (tester) async {
    final provider = _FakeFixProvider(
      onApply: (_) async => FixResult.success(
        FixActionKind.disableIpv6,
        message: 'ok',
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

    await tester.tap(find.text('Apply recommended fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Fix applied'), findsOneWidget);
    expect(find.text('Run diagnostics again'), findsOneWidget);
    await tester.tap(find.text('Run diagnostics again'));
    await tester.pump();
    expect(rerun, isTrue);
  });

  testWidgets('failure uses human-readable message', (tester) async {
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

    await tester.tap(find.text('Apply recommended fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Applying…'), findsOneWidget);

    completer.complete(
      FixResult.failure(
        FixActionKind.disableIpv6,
        message: 'Failed',
        error: 'sysctl: permission denied',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('RouteFix needs administrator permission to continue.'),
      findsOneWidget,
    );
    expect(find.text('View technical details'), findsOneWidget);
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

    await tester.tap(find.text('Apply recommended fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(provider.applyCalls, isEmpty);
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
