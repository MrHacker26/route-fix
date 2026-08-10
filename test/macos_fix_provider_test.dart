import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/macos_fix_provider.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('MacOsFixProvider IPv6', () {
    test('disables IPv6 via privileged osascript on each service', () async {
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
          if (executable == 'route' ||
              (arguments.isNotEmpty &&
                  arguments.first == '-listnetworkserviceorder')) {
            return ProcessResult(1, 1, '', 'not used');
          }
          if (executable == 'osascript') {
            return ProcessResult(1, 0, '', '');
          }
          return ProcessResult(1, 1, '', 'unexpected');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('Prefer IPv4'));
      expect(result.metadata['applied'], 'Wi-Fi, Thunderbolt Bridge');
      expect(commands.first, ['networksetup', '-listallnetworkservices']);
      final osascripts = commands.where((c) => c.first == 'osascript').toList();
      expect(osascripts, hasLength(1));
      expect(osascripts.single[2], contains('-setv6off'));
      expect(osascripts.single[2], contains('Wi-Fi'));
      expect(osascripts.single[2], contains('Thunderbolt Bridge'));
    });

    test('updates all enabled services when active service is detectable', () async {
      final commands = <List<String>>[];
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          if (executable == 'route') {
            return ProcessResult(1, 0, 'interface: en0\n', '');
          }
          if (arguments.isNotEmpty &&
              arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\nEthernet\n', '');
          }
          if (arguments.isNotEmpty &&
              arguments.first == '-listnetworkserviceorder') {
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
          if (executable == 'osascript') {
            return ProcessResult(1, 0, '', '');
          }
          return ProcessResult(1, 1, '', 'unexpected');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.success, isTrue);
      expect(result.metadata['applied'], 'Wi-Fi, Ethernet');
      final scripts =
          commands.where((c) => c.first == 'osascript').map((c) => c[2]).toList();
      expect(scripts, hasLength(1));
      expect(scripts.single, contains('-setv6off'));
      expect(scripts.single, contains('Wi-Fi'));
      expect(scripts.single, contains('Ethernet'));
    });

    test('enables IPv6 with privileged setv6automatic', () async {
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
          if (executable == 'osascript') {
            return ProcessResult(1, 0, '', '');
          }
          return ProcessResult(1, 1, '', 'unexpected');
        },
      );

      final result = await provider.apply(FixActionKind.enableIpv6);

      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(result.message, contains('restored'));
      expect(result.metadata['mode'], 'automatic');
      final scripts =
          commands.where((c) => c.first == 'osascript').map((c) => c[2]).toList();
      expect(scripts, hasLength(1));
      expect(scripts.single, contains('-setv6automatic'));
      expect(scripts.single, contains('with administrator privileges'));
    });

    test('returns UserCancelled when auth dialog is dismissed', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          if (arguments.isNotEmpty &&
              arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\n', '');
          }
          if (executable == 'route' ||
              (arguments.isNotEmpty &&
                  arguments.first == '-listnetworkserviceorder')) {
            return ProcessResult(1, 1, '', 'not used');
          }
          if (executable == 'osascript') {
            return ProcessResult(
              1,
              1,
              '',
              'execution error: User canceled. (-128)',
            );
          }
          return ProcessResult(1, 1, '', 'unexpected');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.wasCancelled, isTrue);
      expect(result.success, isFalse);
      expect(result.executed, isFalse);
      expect(result.message, 'UserCancelled');
    });

    test('returns failure when listing services fails', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          return ProcessResult(1, 1, '', 'permission denied');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);

      expect(result.success, isFalse);
      expect(result.message, contains('Couldn’t find a network service'));
      expect(result.error, contains('No enabled network services'));
    });

    test('returns failure when privileged update fails', () async {
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          if (arguments.isNotEmpty &&
              arguments.first == '-listallnetworkservices') {
            return ProcessResult(1, 0, 'Wi-Fi\n', '');
          }
          if (executable == 'route' ||
              (arguments.isNotEmpty &&
                  arguments.first == '-listnetworkserviceorder')) {
            return ProcessResult(1, 1, '', 'not used');
          }
          if (executable == 'osascript') {
            return ProcessResult(1, 1, '', 'networksetup failed');
          }
          return ProcessResult(1, 1, '', 'unexpected');
        },
      );

      final result = await provider.apply(FixActionKind.disableIpv6);
      expect(result.success, isFalse);
      expect(result.error, contains('networksetup failed'));
    });

    test('flushDns runs privileged cache flush on macOS', () async {
      final commands = <List<String>>[];
      final provider = MacOsFixProvider(
        runProcess: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          if (executable == 'osascript') {
            return ProcessResult(1, 0, '', '');
          }
          return ProcessResult(1, 1, '', 'unexpected');
        },
      );
      final result = await provider.apply(FixActionKind.flushDns);
      expect(result.success, isTrue);
      expect(result.executed, isTrue);
      expect(commands.where((c) => c.first == 'osascript'), isNotEmpty);
    });
  });
}
