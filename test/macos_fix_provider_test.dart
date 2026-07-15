import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/macos_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('MacOsFixProvider IPv6', () {
    test('disables IPv6 on each enabled network service', () async {
      final commands = <List<String>>[];
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          if (arguments.first == '-listallnetworkservices') {
            return ProcessResult(
              1,
              0,
              'An asterisk (*) denotes that a network service is disabled.\n'
                  'Wi-Fi\n'
                  '*iPhone USB\n'
                  'Thunderbolt Bridge\n',
              '',
            );
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('IPv6 disabled'));
      expect(result.metadata['applied'], 'Wi-Fi, Thunderbolt Bridge');
      expect(commands, [
        ['networksetup', '-listallnetworkservices'],
        ['networksetup', '-setv6off', 'Wi-Fi'],
        ['networksetup', '-setv6off', 'Thunderbolt Bridge'],
      ]);
    });

    test('enables IPv6 with setv6automatic', () async {
      final commands = <List<String>>[];
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          if (arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\n', '');
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('IPv6 enabled'));
      expect(result.metadata['mode'], 'automatic');
      expect(commands, [
        ['networksetup', '-listallnetworkservices'],
        ['networksetup', '-setv6automatic', 'Wi-Fi'],
      ]);
    });

    test('returns failure when listing services fails', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(1, 1, '', 'permission denied');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isFalse);
      expect(result.executed, isTrue);
      expect(result.message, 'Failed to disable IPv6.');
      expect(result.error, contains('permission denied'));
    });

    test('returns failure when no service can be updated', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          if (arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\n', '');
          }
          return ProcessResult(1, 1, '', '** Error: service does not support IPv6');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.success, isFalse);
      expect(result.executed, isTrue);
      expect(result.message, 'Failed to enable IPv6.');
      expect(result.error, contains('does not support IPv6'));
    });

    test('succeeds if at least one service applies', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          if (arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\nThunderbolt Bridge\n', '');
          }
          if (arguments.contains('Thunderbolt Bridge')) {
            return ProcessResult(1, 1, '', 'unsupported');
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.metadata['applied'], 'Wi-Fi');
      expect(result.metadata['skipped'], contains('Thunderbolt Bridge'));
    });

    test('leaves comingSoon actions untouched', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          fail('should not run for comingSoon fixes');
        },
      );

      final result = await provider.apply(FixActionKind.flushDns);

      expect(result.executed, isFalse);
      expect(result.error, contains('future release'));
    });
  });
}
