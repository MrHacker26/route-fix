import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/linux_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('LinuxFixProvider', () {
    test('prefer IPv4 succeeds when pkexec sysctl writes succeed', () async {
      final commands = <List<String>>[];
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          return ProcessResult(1, 0, '${arguments.last}\n', '');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('Prefer IPv4'));
      expect(result.error, isNull);
      expect(commands.single.first, 'pkexec');
      expect(commands.single.last, contains('sysctl -w net.ipv6.conf.all.disable_ipv6=1'));
      expect(commands.single.last, contains('sysctl -w net.ipv6.conf.default.disable_ipv6=1'));
    });

    test('restore default re-enables IPv6', () async {
      final commands = <List<String>>[];
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);
      expect(result.success, isTrue);
      expect(result.message, contains('restored'));
      expect(commands.single.first, 'pkexec');
      expect(commands.single.last, contains('sysctl -w net.ipv6.conf.all.disable_ipv6=0'));
    });

    test('returns UserCancelled when pkexec dialog is dismissed', () async {
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(
            1,
            127,
            '',
            'Error dismisses authentication dialog',
          );
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.wasCancelled, isTrue);
      expect(result.success, isFalse);
      expect(result.executed, isFalse);
    });

    test('returns failure when pkexec auth fails', () async {
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(
            1,
            126,
            '',
            'Not authorized',
          );
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isFalse);
      expect(result.executed, isTrue);
      expect(result.message, contains('Admin access'));
      expect(result.error, contains('Not authorized'));
    });

    test('returns failure when the process cannot be started', () async {
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          throw const ProcessException('sysctl', ['-w'], 'not found', 2);
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isFalse);
      expect(result.executed, isFalse);
      expect(result.message, contains('Couldn’t update network settings'));
      expect(result.error, isNotNull);
    });
  });
}
