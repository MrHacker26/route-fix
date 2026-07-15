import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/macos_fix_provider.dart';
import 'package:route_fix/data/autofix/platform_fix_provider_factory.dart';
import 'package:route_fix/domain/autofix/autofix.dart';

void main() {
  group('PlatformFixProvider catalog', () {
    final provider = MacOsFixProvider();

    test('exposes disable/enable IPv6 and future flush/warp actions', () {
      final actions = provider.availableActions();
      final kinds = actions.map((a) => a.kind).toSet();

      expect(
        kinds,
        containsAll([
          FixActionKind.disableIpv6,
          FixActionKind.enableIpv6,
          FixActionKind.flushDns,
          FixActionKind.openWarp,
        ]),
      );

      final flush = actions.firstWhere((a) => a.kind == FixActionKind.flushDns);
      expect(flush.availability, FixAvailability.comingSoon);

      final disable =
          actions.firstWhere((a) => a.kind == FixActionKind.disableIpv6);
      expect(disable.availability, FixAvailability.available);
      expect(disable.title, 'Prefer IPv4');
      expect(disable.supportsPlatform(FixPlatform.macOS), isTrue);
    });

    test('future actions return comingSoon without executing', () async {
      final result = await provider.apply(FixActionKind.openWarp);

      expect(result.executed, isFalse);
      expect(result.error, contains('future release'));
    });
  });

  test('factory selects a PlatformFixProvider for this host', () {
    final FixProvider provider = const PlatformFixProviderFactory().create();
    expect(provider, isA<PlatformFixProvider>());
    expect(provider, isA<FixProvider>());
    expect(provider.availableActions(), isNotEmpty);
  });
}
