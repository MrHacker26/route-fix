import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/design_system/design_system.dart';
import 'package:route_fix/domain/autofix/auto_fix_service.dart';
import 'package:route_fix/domain/autofix/models/applied_fix.dart';
import 'package:route_fix/domain/autofix/models/fix_action.dart';
import 'package:route_fix/domain/autofix/models/fix_result.dart';
import 'package:route_fix/domain/autofix/models/fix_type.dart';
import 'package:route_fix/domain/autofix/platform_fix_executor.dart';
import 'package:route_fix/domain/autofix/shell_command_executor.dart';
import 'package:route_fix/features/network_controls/ipv6_preference.dart';
import 'package:route_fix/features/network_controls/ipv6_preference_probe.dart';
import 'package:route_fix/features/network_controls/network_controls_controller.dart';
import 'package:route_fix/features/network_controls/network_controls_page.dart';

void main() {
  testWidgets('Network Controls shows configuration card and radios', (
    tester,
  ) async {
    final autoFix = _FakeAutoFix();
    final controller = NetworkControlsController(
      autoFix: autoFix,
      probe: Ipv6PreferenceProbe(
        shell: _StaticShell(
          const ShellCommandResult(
            executable: 'sysctl',
            arguments: ['-n', 'net.ipv6.conf.all.disable_ipv6'],
            exitCode: 0,
            stdout: '0',
            stderr: '',
          ),
        ),
        autoFix: autoFix,
        platformOverride: FixPlatform.linux,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: NetworkControlsPage(
          autoFix: autoFix,
          controller: controller,
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Network Controls'), findsOneWidget);
    expect(find.text('Network Configuration'), findsOneWidget);
    expect(find.text('Manually control network preferences.'), findsOneWidget);
    expect(find.text('Automatic (Recommended)'), findsOneWidget);
    expect(find.text('Prefer IPv4'), findsOneWidget);
    expect(find.text('Disable IPv6'), findsOneWidget);
    expect(find.text('Apply Changes'), findsOneWidget);
    expect(find.text('Restore Defaults'), findsOneWidget);
    expect(find.text('Automatic'), findsWidgets);

    final apply = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Apply Changes'),
    );
    expect(apply.onPressed, isNull);

    await tester.tap(find.text('Prefer IPv4'));
    await tester.pumpAndSettle();

    final applyAfter = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Apply Changes'),
    );
    expect(applyAfter.onPressed, isNotNull);
  });
}

final class _StaticShell implements ShellCommandExecutor {
  _StaticShell(this.result);

  final ShellCommandResult result;

  @override
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async =>
      result;
}

final class _FakeAutoFix implements AutoFixService {
  @override
  FixPlatform get platform => FixPlatform.linux;

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
    return FixResult.success(
      FixActionKind.disableIpv6,
      message: 'ok',
      platform: platform,
    );
  }

  @override
  Future<FixResult> restoreDefault({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    return FixResult.success(
      FixActionKind.enableIpv6,
      message: 'ok',
      platform: platform,
    );
  }
}
