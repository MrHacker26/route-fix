import '../../core/errors/app_failure.dart';

/// HTTP probe outcome tagged with the target hostname.
class HostHttpProbeResult {
  const HostHttpProbeResult({
    required this.hostname,
    required this.success,
    this.latency,
    this.httpStatus,
    this.failure,
  });

  final String hostname;
  final bool success;
  final Duration? latency;
  final int? httpStatus;

  /// Structured failure when [success] is false.
  final AppFailure? failure;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}

/// Combined PyPI index + files host probe results.
class PypiDiagnosticsResult {
  const PypiDiagnosticsResult({
    required this.index,
    required this.files,
  });

  /// Result for `pypi.org`.
  final HostHttpProbeResult index;

  /// Result for `files.pythonhosted.org`.
  final HostHttpProbeResult files;

  /// Both targets reachable with a successful HTTP status.
  bool get success => index.success && files.success;

  List<HostHttpProbeResult> get targets => [index, files];
}
