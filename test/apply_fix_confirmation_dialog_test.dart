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
    description:
        'RouteFix detected an IPv6 routing issue. '
        'Temporarily preferring IPv4 may improve connectivity on this network.',
    why: 'IPv6 is responding about 18× slower than IPv4 right now.',
    whyThisRecommendation:
        'Prefer IPv4 when the IPv6 path is clearly slower or unavailable.',
    confidenceLabel: 'Strong',
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

  testWidgets('shows Prefer IPv4 recommendation before apply', (tester) async {
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
          autoFix: _FakeAutoFixService(
            onApply: (_) async => FixResult.success(
              FixActionKind.disableIpv6,
              message: 'ok',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recommended Fix'), findsOneWidget);
    expect(find.text('Prefer IPv4'), findsOneWidget);
    expect(find.text('Apply Fix'), findsOneWidget);
  });

  testWidgets('success dialog offers run diagnostics again', (tester) async {
    final service = _FakeAutoFixService(
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
          fixProvider: _FakeFixProvider(
            onApply: (_) async => FixResult.success(
              FixActionKind.disableIpv6,
              message: 'ok',
            ),
          ),
          autoFix: service,
          onRerunDiagnostics: () => rerun = true,
        ),
      ),
    );

    await tester.tap(find.text('Apply Fix'));
    await tester.pumpAndSettle();
    expect(find.text('Prefer IPv4?'), findsOneWidget);
    await tester.tap(find.text('Apply Fix').last);
    await tester.pumpAndSettle();

    expect(find.text('Network Updated'), findsWidgets);
    await tester.tap(find.text('Run Again').last);
    await tester.pumpAndSettle();
    expect(rerun, isTrue);
  });

  testWidgets('failure uses human-readable message with expandable stderr',
      (tester) async {
    final completer = Completer<FixResult>();
    final service = _FakeAutoFixService(onApply: (_) => completer.future);

    await tester.pumpWidget(
      wrap(
        RecommendedFixCard(
          fix: fix,
          fixProvider: _FakeFixProvider(
            onApply: (_) async => FixResult.failure(
              FixActionKind.disableIpv6,
              message: 'Failed',
            ),
          ),
          autoFix: service,
        ),
      ),
    );

    await tester.tap(find.text('Apply Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply Fix').last);
    await tester.pump();

    expect(find.textContaining('Applying'), findsWidgets);

    completer.complete(
      FixResult.failure(
        FixActionKind.disableIpv6,
        message: 'RouteFix needs administrator permission to continue.',
        error: 'sysctl: permission denied',
        metadata: const {'stderr': 'sysctl: permission denied'},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('RouteFix needs administrator permission to continue.'),
      findsOneWidget,
    );
    expect(find.text('View technical details'), findsOneWidget);
  });

  testWidgets('cancel does not call auto fix service', (tester) async {
    final service = _FakeAutoFixService(
      onApply: (_) async => FixResult.success(
        FixActionKind.disableIpv6,
        message: 'ok',
      ),
    );

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
          autoFix: service,
        ),
      ),
    );

    await tester.tap(find.text('Apply Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.applyCalls, isEmpty);
  });
}

final class _FakeFixProvider implements FixProvider {
  _FakeFixProvider({required this.onApply});

  final Future<FixResult> Function(FixActionKind kind) onApply;

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  List<FixAction> availableActions() => const [];

  @override
  bool supports(FixActionKind kind) => true;

  @override
  Future<FixResult> apply(FixActionKind kind) => onApply(kind);
}

final class _FakeAutoFixService implements AutoFixService {
  _FakeAutoFixService({required this.onApply});

  final Future<FixResult> Function(FixType type) onApply;
  final List<FixType> applyCalls = [];

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  bool get isBusy => false;

  @override
  Stream<AutoFixPhase> get progress => const Stream.empty();

  @override
  List<AppliedFix> get appliedFixes => const [];

  @override
  bool supports(FixType type) => true;

  @override
  Future<FixResult> apply(
    FixType type, {
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    applyCalls.add(type);
    onPhase?.call(AutoFixPhase.applying);
    return onApply(type);
  }

  @override
  Future<FixResult> restoreDefault({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    return FixResult.success(
      FixActionKind.enableIpv6,
      message: 'restored',
    );
  }
}
