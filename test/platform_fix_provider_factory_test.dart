import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/linux_fix_provider.dart';
import 'package:route_fix/data/autofix/macos_fix_provider.dart';
import 'package:route_fix/data/autofix/platform_fix_provider_factory.dart';
import 'package:route_fix/data/autofix/windows_fix_provider.dart';
import 'package:route_fix/di/app_services.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  tearDown(AppServices.reset);

  group('PlatformFixProviderFactory', () {
    test('detectHostPlatform matches dart:io Platform', () {
      final detected = PlatformFixProviderFactory.detectHostPlatform();

      if (Platform.isLinux) {
        expect(detected, FixPlatform.linux);
      } else if (Platform.isMacOS) {
        expect(detected, FixPlatform.macOS);
      } else if (Platform.isWindows) {
        expect(detected, FixPlatform.windows);
      } else {
        expect(detected, FixPlatform.unsupported);
      }
    });

    test('create returns FixProvider for the host without executing fixes', () {
      final FixProvider provider = const PlatformFixProviderFactory().create();

      expect(provider, isA<FixProvider>());
      expect(provider, isA<PlatformFixProvider>());
      expect(provider.platform, isNot(FixPlatform.unsupported));
      expect(provider.availableActions(), isNotEmpty);
    });

    test('createFor maps Linux / macOS / Windows', () {
      const factory = PlatformFixProviderFactory();

      expect(factory.createFor(FixPlatform.linux), isA<LinuxFixProvider>());
      expect(factory.createFor(FixPlatform.macOS), isA<MacOsFixProvider>());
      expect(factory.createFor(FixPlatform.windows), isA<WindowsFixProvider>());
      expect(
        factory.createFor(FixPlatform.unsupported),
        isA<UnsupportedFixProvider>(),
      );
    });

    test('providers map allows future platform registration', () {
      final factory = PlatformFixProviderFactory(
        providers: {
          FixPlatform.unsupported: () => const _FuturePlatformFixProvider(),
        },
      );

      final provider = factory.createFor(FixPlatform.unsupported);

      expect(provider, isA<_FuturePlatformFixProvider>());
      expect(provider.platform, FixPlatform.unsupported);
    });

    test('platformOverride bypasses host detection', () {
      final FixProvider provider = const PlatformFixProviderFactory(
        platformOverride: FixPlatform.windows,
      ).create();

      expect(provider, isA<WindowsFixProvider>());
      expect(provider.platform, FixPlatform.windows);
    });

    test('createPlatformFixProvider exposes FixProvider only', () {
      final FixProvider provider = createPlatformFixProvider(
        platformOverride: FixPlatform.linux,
      );

      expect(provider.platform, FixPlatform.linux);
    });
  });

  group('AppServices.fixProvider', () {
    test('exposes a single FixProvider for the application', () {
      final FixProvider provider = AppServices.fixProvider;

      expect(provider, same(AppServices.fixProvider));
      expect(provider, isA<PlatformFixProvider>());
    });
  });
}

final class _FuturePlatformFixProvider extends PlatformFixProvider {
  const _FuturePlatformFixProvider();

  @override
  FixPlatform get platform => FixPlatform.unsupported;

  @override
  Future<FixResult> applyStub(FixActionKind kind) async {
    return FixResult.notImplemented(kind);
  }
}
