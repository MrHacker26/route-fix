import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/windows/windows_admin_requirement.dart';
import 'package:route_fix/data/autofix/windows/windows_ipv6_fix_commands.dart';
import 'package:route_fix/data/autofix/windows_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('WindowsFixProvider', () {
    test('marks IPv6 actions as requiring elevation', () {
      const provider = WindowsFixProvider();
      final actions = provider.availableActions();

      final disable =
          actions.firstWhere((a) => a.kind == FixActionKind.disableIpv6);
      final enable =
          actions.firstWhere((a) => a.kind == FixActionKind.enableIpv6);

      expect(disable.availability, FixAvailability.requiresElevation);
      expect(enable.availability, FixAvailability.requiresElevation);
    });

    test('prepare disable IPv6 without executing', () async {
      const provider = WindowsFixProvider();

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isFalse);
      expect(result.platform, FixPlatform.windows);
      expect(result.requiresElevation, isTrue);
      expect(result.message, contains('not executed'));
      expect(result.executedCommand, contains('powershell.exe'));
      expect(result.executedCommand, contains('Disable-NetAdapterBinding'));
      expect(result.executedCommand, contains('ms_tcpip6'));
      expect(result.metadata['execution'], 'deferred');
      expect(result.metadata['netsh'], contains('netsh interface ipv6'));
    });

    test('prepare enable IPv6 without executing', () async {
      const provider = WindowsFixProvider();

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isFalse);
      expect(result.platform, FixPlatform.windows);
      expect(result.requiresElevation, isTrue);
      expect(result.executedCommand, contains('Enable-NetAdapterBinding'));
      expect(result.message, contains('enable IPv6'));
    });

    test('reports elevation status when a probe is supplied', () async {
      final provider = WindowsFixProvider(
        adminResolver: WindowsAdminRequirementResolver(
          elevationProbe: () async => true,
        ),
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isFalse);
      expect(result.requiresElevation, isFalse);
      expect(result.metadata['isElevated'], 'true');
      expect(result.message, contains('elevated'));
    });

    test('requiresElevation stays true when probe reports not elevated',
        () async {
      final provider = WindowsFixProvider(
        adminResolver: WindowsAdminRequirementResolver(
          elevationProbe: () async => false,
        ),
      );

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.requiresElevation, isTrue);
      expect(result.metadata['isElevated'], 'false');
      expect(result.message, contains('not elevated'));
    });

    test('exposes only FixProvider surface for future actions', () async {
      const provider = WindowsFixProvider();
      final result = await provider.apply(FixActionKind.openWarp);

      expect(result.executed, isFalse);
      expect(result.error, contains('future release'));
    });
  });

  group('WindowsIpv6FixCommands', () {
    test('builds distinct disable and enable PowerShell commands', () {
      const commands = WindowsIpv6FixCommands();

      final disable = commands.disableIpv6PowerShell();
      final enable = commands.enableIpv6PowerShell();

      expect(disable, isNot(equals(enable)));
      expect(disable, contains('Disable-NetAdapterBinding'));
      expect(enable, contains('Enable-NetAdapterBinding'));
    });
  });
}
