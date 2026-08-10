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
import 'package:route_fix/features/network_controls/dns_preference_probe.dart';
import 'package:route_fix/features/network_controls/ipv6_preference_probe.dart';
import 'package:route_fix/features/network_controls/network_controls_controller.dart';
import 'package:route_fix/features/network_controls/network_controls_page.dart';

void main() {
  testWidgets('Network Controls shows configuration card and radios', (
    tester,
  ) async {
    final autoFix = _FakeAutoFix();
    final shell = _StaticShell(
      const ShellCommandResult(
        executable: 'sysctl',
        arguments: ['-n', 'net.ipv6.conf.all.disable_ipv6'],
        exitCode: 0,
        stdout: '0',
        stderr: '',
      ),
      const ShellCommandResult(
        executable: 'ip',
        arguments: ['-4', 'route', 'show', 'default'],
        exitCode: 0,
        stdout: 'default via 192.168.1.1 dev wlan0 proto dhcp\n',
        stderr: '',
      ),
      const ShellCommandResult(
        executable: 'resolvectl',
        arguments: ['dns', 'wlan0'],
        exitCode: 0,
        stdout: '',
        stderr: '',
      ),
    );
    final controller = NetworkControlsController(
      autoFix: autoFix,
      probe: Ipv6PreferenceProbe(
        shell: shell,
        autoFix: autoFix,
        platformOverride: FixPlatform.linux,
      ),
      dnsProbe: DnsPreferenceProbe(shell: shell, autoFix: autoFix),
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
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Choose how this device prefers network paths.'), findsOneWidget);
    expect(find.text('Connection preference'), findsOneWidget);
    expect(find.text('Automatic'), findsWidgets);
    expect(find.text('Prefer IPv4'), findsOneWidget);
    expect(find.text('Disable IPv6'), findsNothing);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Restore defaults'), findsOneWidget);

    final apply = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Apply'),
    );
    expect(apply.onPressed, isNull);

    await tester.tap(find.text('Prefer IPv4'));
    await tester.pumpAndSettle();

    final applyAfter = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Apply'),
    );
    expect(applyAfter.onPressed, isNotNull);
  });
}

final class _StaticShell implements ShellCommandExecutor {
  _StaticShell(this.primary, [this.secondary, this.tertiary]);

  final ShellCommandResult primary;
  final ShellCommandResult? secondary;
  final ShellCommandResult? tertiary;

  @override
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async {
    final key = [executable, ...arguments].join('|');
    if (key == 'ip|-4|route|show|default' && secondary != null) {
      return secondary!;
    }
    if (key == 'resolvectl|dns|wlan0' && tertiary != null) {
      return tertiary!;
    }
    return primary;
  }
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
    Map<String, String>? context,
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
