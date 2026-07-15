import 'package:flutter_test/flutter_test.dart';
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

void main() {
  group('Ipv6PreferenceProbe', () {
    test('detects Automatic on macOS from getinfo', () async {
      final autoFix = _FakeAutoFix();
      final probe = Ipv6PreferenceProbe(
        shell: _FakeShell({
          'networksetup|-listallnetworkservices': const ShellCommandResult(
            executable: 'networksetup',
            arguments: ['-listallnetworkservices'],
            exitCode: 0,
            stdout: 'Wi-Fi\n',
            stderr: '',
          ),
          'networksetup|-getinfo|Wi-Fi': const ShellCommandResult(
            executable: 'networksetup',
            arguments: ['-getinfo', 'Wi-Fi'],
            exitCode: 0,
            stdout: 'IPv6: Automatic\nIP address: 192.168.1.2\n',
            stderr: '',
          ),
        }),
        autoFix: autoFix,
        platformOverride: FixPlatform.macOS,
      );

      final result = await probe.detect();
      expect(result.preference, Ipv6Preference.automatic);
    });

    test('detects IPv6 Disabled when off and Auto Fix did not apply', () async {
      final autoFix = _FakeAutoFix();
      final probe = Ipv6PreferenceProbe(
        shell: _FakeShell({
          'networksetup|-listallnetworkservices': const ShellCommandResult(
            executable: 'networksetup',
            arguments: ['-listallnetworkservices'],
            exitCode: 0,
            stdout: 'Wi-Fi\n',
            stderr: '',
          ),
          'networksetup|-getinfo|Wi-Fi': const ShellCommandResult(
            executable: 'networksetup',
            arguments: ['-getinfo', 'Wi-Fi'],
            exitCode: 0,
            stdout: 'IPv6: Off\n',
            stderr: '',
          ),
        }),
        autoFix: autoFix,
        platformOverride: FixPlatform.macOS,
      );

      final result = await probe.detect();
      expect(result.preference, Ipv6Preference.disableIpv6);
    });

    test('returns Unknown when detection fails', () async {
      final probe = Ipv6PreferenceProbe(
        shell: _FakeShell({}),
        autoFix: _FakeAutoFix(),
        platformOverride: FixPlatform.macOS,
      );

      final result = await probe.detect();
      expect(result.preference, Ipv6Preference.unknown);
    });
  });

  group('NetworkControlsController', () {
    test('Apply Changes stays disabled until selection changes', () async {
      final autoFix = _FakeAutoFix();
      final controller = NetworkControlsController(
        autoFix: autoFix,
        probe: Ipv6PreferenceProbe(
          shell: _FakeShell({
            'sysctl|-n|net.ipv6.conf.all.disable_ipv6': const ShellCommandResult(
              executable: 'sysctl',
              arguments: ['-n', 'net.ipv6.conf.all.disable_ipv6'],
              exitCode: 0,
              stdout: '0',
              stderr: '',
            ),
          }),
          autoFix: autoFix,
          platformOverride: FixPlatform.linux,
        ),
      );

      await controller.load();
      expect(controller.detected, Ipv6Preference.automatic);
      expect(controller.hasPendingChanges, isFalse);

      controller.select(Ipv6Preference.preferIpv4);
      expect(controller.hasPendingChanges, isTrue);
    });

    test('Prefer IPv4 applies via AutoFixService.preferIpv4', () async {
      final autoFix = _FakeAutoFix();
      final controller = NetworkControlsController(
        autoFix: autoFix,
        probe: Ipv6PreferenceProbe(
          shell: _FakeShell({
            'sysctl|-n|net.ipv6.conf.all.disable_ipv6': const ShellCommandResult(
              executable: 'sysctl',
              arguments: ['-n', 'net.ipv6.conf.all.disable_ipv6'],
              exitCode: 0,
              stdout: '0',
              stderr: '',
            ),
          }),
          autoFix: autoFix,
          platformOverride: FixPlatform.linux,
        ),
      );

      await controller.load();
      controller.select(Ipv6Preference.disableIpv6);
      final result = await controller.applySelection();

      expect(result.success, isTrue);
      expect(autoFix.applyCalls, [FixType.preferIpv4]);
    });

    test('Restore Defaults uses AutoFixService.restoreDefault', () async {
      final autoFix = _FakeAutoFix();
      final controller = NetworkControlsController(
        autoFix: autoFix,
        probe: Ipv6PreferenceProbe(
          shell: _FakeShell({
            'sysctl|-n|net.ipv6.conf.all.disable_ipv6': const ShellCommandResult(
              executable: 'sysctl',
              arguments: ['-n', 'net.ipv6.conf.all.disable_ipv6'],
              exitCode: 0,
              stdout: '1',
              stderr: '',
            ),
          }),
          autoFix: autoFix,
          platformOverride: FixPlatform.linux,
        ),
      );

      await controller.load();
      final result = await controller.restoreDefaults();
      expect(result.success, isTrue);
      expect(autoFix.restoreCalls, 1);
    });
  });
}

final class _FakeShell implements ShellCommandExecutor {
  _FakeShell(this.responses);

  final Map<String, ShellCommandResult> responses;

  @override
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async {
    final key = [executable, ...arguments].join('|');
    return responses[key] ??
        ShellCommandResult(
          executable: executable,
          arguments: arguments,
          exitCode: 1,
          stdout: '',
          stderr: 'missing mock for $key',
        );
  }
}

final class _FakeAutoFix implements AutoFixService {
  final List<FixType> applyCalls = [];
  var restoreCalls = 0;
  final List<AppliedFix> _applied = [];

  @override
  FixPlatform get platform => FixPlatform.linux;

  @override
  bool get isBusy => false;

  @override
  Stream<AutoFixPhase> get progress => const Stream.empty();

  @override
  List<AppliedFix> get appliedFixes => List.unmodifiable(_applied);

  @override
  bool supports(FixType type) =>
      type == FixType.preferIpv4 || type == FixType.restoreDefault;

  @override
  Future<FixResult> apply(
    FixType type, {
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    applyCalls.add(type);
    if (type == FixType.preferIpv4) {
      _applied
        ..clear()
        ..add(
          AppliedFix(
            id: 'test',
            type: type,
            appliedAt: DateTime.now().toUtc(),
            platform: platform.name,
          ),
        );
    }
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
    restoreCalls += 1;
    _applied.clear();
    return FixResult.success(
      FixActionKind.enableIpv6,
      message: 'restored',
      platform: platform,
    );
  }
}
