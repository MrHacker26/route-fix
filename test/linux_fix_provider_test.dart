import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/linux_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('LinuxFixProvider disableIpv6', () {
    test('returns success when both sysctl writes succeed', () async {
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
      expect(result.message, contains('IPv6 disabled'));
      expect(result.error, isNull);
      expect(commands, [
        ['sysctl', '-w', 'net.ipv6.conf.all.disable_ipv6=1'],
        ['sysctl', '-w', 'net.ipv6.conf.default.disable_ipv6=1'],
      ]);
    });

    test('returns failure when sysctl exits non-zero', () async {
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(
            1,
            1,
            '',
            'sysctl: permission denied',
          );
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isFalse);
      expect(result.executed, isTrue);
      expect(result.message, 'Failed to disable IPv6.');
      expect(result.error, contains('permission denied'));
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
      expect(result.message, 'Failed to disable IPv6.');
      expect(result.error, isNotNull);
    });

    test('does not implement enableIpv6 yet', () async {
      final provider = LinuxFixProvider(
        runProcess: (executable, arguments) async {
          fail('should not run for unimplemented fixes');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.success, isFalse);
      expect(result.executed, isFalse);
      expect(result.error, contains('not implemented'));
    });
  });
}
