import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/executors/linux_privileged_sysctl.dart';
import 'package:route_fix/domain/autofix/shell_command_executor.dart';

void main() {
  group('LinuxPrivilegedSysctl', () {
    test('runs sysctl writes through pkexec', () async {
      final calls = <List<String>>[];
      final privileged = LinuxPrivilegedSysctl(
        shell: _RecordingShell(calls),
      );

      final result = await privileged.runSettings(const [
        'net.ipv6.conf.all.disable_ipv6=1',
        'net.ipv6.conf.default.disable_ipv6=1',
      ]);

      expect(result.isSuccess, isTrue);
      expect(calls.single.first, 'pkexec');
      expect(calls.single.last, contains('sysctl -w net.ipv6.conf.all.disable_ipv6=1'));
      expect(calls.single.last, contains('sysctl -w net.ipv6.conf.default.disable_ipv6=1'));
    });

    test('maps dismissed pkexec dialog to cancelled', () async {
      final privileged = LinuxPrivilegedSysctl(
        shell: _StaticShell(
          const ShellCommandResult(
            executable: 'pkexec',
            arguments: ['sh', '-c', 'sysctl -w x=1'],
            exitCode: 127,
            stdout: '',
            stderr: 'Error dismisses authentication dialog',
          ),
        ),
      );

      final result = await privileged.runSettings(const [
        'net.ipv6.conf.all.disable_ipv6=1',
      ]);

      expect(result.isCancelled, isTrue);
    });
  });
}

final class _RecordingShell implements ShellCommandExecutor {
  _RecordingShell(this.calls);

  final List<List<String>> calls;

  @override
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async {
    calls.add([executable, ...arguments]);
    return ShellCommandResult(
      executable: executable,
      arguments: arguments,
      exitCode: 0,
      stdout: 'ok',
      stderr: '',
    );
  }
}

final class _StaticShell implements ShellCommandExecutor {
  _StaticShell(this.result);

  final ShellCommandResult result;

  @override
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async =>
      result;
}
