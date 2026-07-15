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
          if (arguments.isNotEmpty &&
              arguments.first == '-listallnetworkservices') {
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
          // Active-service probes fail closed → fall back to all enabled.
          if (executable == 'route' ||
              (arguments.isNotEmpty &&
                  arguments.first == '-listnetworkserviceorder')) {
            return ProcessResult(1, 1, '', 'not used');
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('Prefer IPv4'));
      expect(result.metadata['applied'], 'Wi-Fi, Thunderbolt Bridge');
      expect(commands.first, ['networksetup', '-listallnetworkservices']);
      expect(
        commands.where((c) => c.length >= 3 && c[1] == '-setv6off').toList(),
        [
          ['networksetup', '-setv6off', 'Wi-Fi'],
          ['networksetup', '-setv6off', 'Thunderbolt Bridge'],
        ],
      );
    });

    test('prefers the active service when detectable', () async {
      final commands = <List<String>>[];
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          if (executable == 'route') {
            return ProcessResult(1, 0, 'interface: en0\n', '');
          }
          if (arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\nEthernet\n', '');
          }
          if (arguments.first == '-listnetworkserviceorder') {
            return ProcessResult(
              1,
              0,
              '(1) Wi-Fi\n'
                  '(Hardware Port: Wi-Fi, Device: en0)\n'
                  '(2) Ethernet\n'
                  '(Hardware Port: Ethernet, Device: en1)\n',
              '',
            );
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.success, isTrue);
      expect(result.metadata['applied'], 'Wi-Fi');
      expect(
        commands.where((c) => c.contains('-setv6off')).toList(),
        [
          ['networksetup', '-setv6off', 'Wi-Fi'],
        ],
      );
    });

    test('enables IPv6 with setv6automatic', () async {
      final commands = <List<String>>[];
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          if (arguments.isNotEmpty &&
              arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\n', '');
          }
          if (executable == 'route' ||
              (arguments.isNotEmpty &&
                  arguments.first == '-listnetworkserviceorder')) {
            return ProcessResult(1, 1, '', 'not used');
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('restored'));
      expect(result.metadata['mode'], 'automatic');
      expect(
        commands.where((c) => c.contains('-setv6automatic')).toList(),
        [
          ['networksetup', '-setv6automatic', 'Wi-Fi'],
        ],
      );
    });

    test('returns failure when listing services fails', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(1, 1, '', 'permission denied');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isFalse);
      expect(result.message, contains('Could not prefer IPv4'));
      expect(result.error, contains('No enabled network services'));
    });

    test('returns failure when no service could be updated', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          if (arguments.isNotEmpty &&
              arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\n', '');
          }
          return ProcessResult(1, 1, '', 'permission denied');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.success, isFalse);
      expect(result.error, contains('permission denied'));
    });

    test('returns notImplemented for flushDns', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          fail('should not run');
        },
      );
      final result = await provider.apply(FixActionKind.flushDns);
      expect(result.success, isFalse);
      expect(result.executed, isFalse);
    });
  });
}
