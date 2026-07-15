import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/repository/in_memory_auto_fix_repository.dart';
import 'package:route_fix/data/autofix/service/default_auto_fix_service.dart';
import 'package:route_fix/data/autofix/shell/dart_io_shell_command_executor.dart';
import 'package:route_fix/domain/autofix/autofix.dart';
import 'package:route_fix/data/autofix/executors/macos_platform_fix_executor.dart';

void main() {
  test('DefaultAutoFixService applies Prefer IPv4 and records AppliedFix',
      () async {
    final repo = InMemoryAutoFixRepository();
    final service = DefaultAutoFixService(
      executor: MacOsPlatformFixExecutor(
        shell: DartIoShellCommandExecutor(
          runProcess: (executable, arguments) async {
            if (arguments.isNotEmpty &&
                arguments.first == '-listallnetworkservices') {
              return ProcessResult(1, 0, 'Wi-Fi\n', '');
            }
            if (executable == 'route' ||
                (arguments.isNotEmpty &&
                    arguments.first == '-listnetworkserviceorder')) {
              return ProcessResult(1, 1, '', 'skip probe');
            }
            return ProcessResult(1, 0, '', '');
          },
        ),
      ),
      repository: repo,
    );

    final phases = <AutoFixPhase>[];
    final result = await service.apply(
      FixType.preferIpv4,
      onPhase: phases.add,
    );

    expect(result.success, isTrue);
    expect(await repo.hasApplied(FixType.preferIpv4), isTrue);
    expect(service.appliedFixes, isNotEmpty);
    expect(phases, contains(AutoFixPhase.applying));
    expect(phases, contains(AutoFixPhase.updatingNetwork));
  });

  test('DefaultAutoFixService restoreDefault clears applied fixes', () async {
    final repo = InMemoryAutoFixRepository();
    final service = DefaultAutoFixService(
      executor: MacOsPlatformFixExecutor(
        shell: DartIoShellCommandExecutor(
          runProcess: (executable, arguments) async {
            if (arguments.isNotEmpty &&
                arguments.first == '-listallnetworkservices') {
              return ProcessResult(1, 0, 'Wi-Fi\n', '');
            }
            if (executable == 'route' ||
                (arguments.isNotEmpty &&
                    arguments.first == '-listnetworkserviceorder')) {
              return ProcessResult(1, 1, '', 'skip probe');
            }
            return ProcessResult(1, 0, '', '');
          },
        ),
      ),
      repository: repo,
    );

    await service.apply(FixType.preferIpv4);
    final restored = await service.restoreDefault();

    expect(restored.success, isTrue);
    expect(await repo.hasApplied(FixType.preferIpv4), isFalse);
    expect(service.appliedFixes, isEmpty);
  });

  test('rejects concurrent applies', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final repo = InMemoryAutoFixRepository();
    final service = DefaultAutoFixService(
      executor: _SlowExecutor(started: started, release: release),
      repository: repo,
    );

    final first = service.apply(FixType.preferIpv4);
    await started.future;
    expect(service.isBusy, isTrue);

    final second = await service.apply(FixType.preferIpv4);
    expect(second.success, isFalse);
    expect(second.message, contains('already in progress'));

    release.complete();
    final firstResult = await first;
    expect(firstResult.success, isTrue);
    expect(service.isBusy, isFalse);
  });
}

final class _SlowExecutor implements PlatformFixExecutor {
  _SlowExecutor({required this.started, required this.release});

  final Completer<void> started;
  final Completer<void> release;

  @override
  FixPlatform get platform => FixPlatform.macOS;

  @override
  bool supports(FixType type) => true;

  @override
  Future<FixResult> apply(FixType type) async {
    started.complete();
    await release.future;
    return FixResult.success(
      FixActionKind.disableIpv6,
      message: 'ok',
      platform: platform,
    );
  }
}
