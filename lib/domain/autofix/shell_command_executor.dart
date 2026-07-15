/// Outcome of a single shell invocation.
final class ShellCommandResult {
  const ShellCommandResult({
    required this.executable,
    required this.arguments,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final String executable;
  final List<String> arguments;
  final int exitCode;
  final String stdout;
  final String stderr;

  bool get isSuccess => exitCode == 0;

  String get commandLine =>
      [executable, ...arguments.map(_quoteIfNeeded)].join(' ');

  static String _quoteIfNeeded(String value) {
    if (value.isEmpty) return '""';
    final needsQuotes = value.contains(' ') ||
        value.contains('\t') ||
        value.contains('"') ||
        value.contains("'");
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', r'\"')}"';
  }
}

/// Runs host processes with an argv list — never a concatenated shell string.
abstract interface class ShellCommandExecutor {
  Future<ShellCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  });
}
