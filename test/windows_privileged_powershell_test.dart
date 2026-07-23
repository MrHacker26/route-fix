import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/executors/windows_privileged_powershell.dart';
import 'package:route_fix/domain/autofix/shell_command_executor.dart';

void main() {
  group('WindowsPrivilegedPowerShell', () {
    test('launches elevated PowerShell with encoded command', () async {
      final calls = <List<String>>[];
      final privileged = WindowsPrivilegedPowerShell(
        shell: _RecordingShell(calls),
      );

      const script =
          r'Get-NetAdapter | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }';
      final result = await privileged.runScript(script);

      expect(result.isSuccess, isTrue);
      expect(calls.single.first, 'powershell.exe');
      expect(calls.single.join(' '), contains('Start-Process'));
      expect(calls.single.join(' '), contains('-Verb RunAs'));
      expect(calls.single.join(' '), contains('-EncodedCommand'));
    });

    test('maps UAC cancel exit code to cancelled', () async {
      final privileged = WindowsPrivilegedPowerShell(
        shell: _StaticShell(
          const ShellCommandResult(
            executable: 'powershell.exe',
            arguments: ['-Command'],
            exitCode: 1220,
            stdout: '',
            stderr: '',
          ),
        ),
      );

      final result = await privileged.runScript('exit 0');
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
      stdout: '',
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
