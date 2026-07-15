import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/windows/windows_ipv6_fix_commands.dart';
import 'package:route_fix/data/autofix/windows_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('WindowsFixProvider', () {
    test('marks IPv6 actions as requiring elevation', () {
      final provider = WindowsFixProvider(
        runProcess: (executable, arguments) async {
          fail('should not run while listing actions');
        },
      );
      final actions = provider.availableActions();

      final disable =
          actions.firstWhere((a) => a.kind == FixActionKind.disableIpv6);
      final enable =
          actions.firstWhere((a) => a.kind == FixActionKind.enableIpv6);

      expect(disable.title, 'Prefer IPv4');
      expect(enable.title, 'Restore Default Network Configuration');
      expect(disable.availability, FixAvailability.requiresElevation);
      expect(enable.availability, FixAvailability.requiresElevation);
    });

    test('executes Prefer IPv4 via PowerShell argv', () async {
      final commands = <List<String>>[];
      final provider = WindowsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.platform, FixPlatform.windows);
      expect(result.requiresElevation, isTrue);
      expect(result.message, contains('Prefer IPv4'));
      expect(commands.single.first, 'powershell.exe');
      expect(commands.single.join(' '), contains('Disable-NetAdapterBinding'));
      expect(commands.single.join(' '), contains('ms_tcpip6'));
    });

    test('executes restore via PowerShell', () async {
      final provider = WindowsFixProvider(
        runProcess: (executable, arguments) async {
          expect(arguments.join(' '), contains('Enable-NetAdapterBinding'));
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);
      expect(result.success, isTrue);
      expect(result.message, contains('restored'));
    });

    test('maps permission failures to a calm message', () async {
      final provider = WindowsFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(1, 1, '', 'Access is denied.');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.success, isFalse);
      expect(result.message, contains('administrator permission'));
      expect(result.error, contains('Access is denied'));
    });

    test('exposes comingSoon for future actions', () async {
      final provider = WindowsFixProvider(
        runProcess: (executable, arguments) async {
          fail('should not run for unimplemented fixes');
        },
      );
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
