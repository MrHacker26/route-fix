/// HTTP probe outcome tagged with the target hostname.
class HostHttpProbeResult {
  const HostHttpProbeResult({
    required this.hostname,
    required this.success,
    this.latency,
    this.httpStatus,
    this.error,
  });

  final String hostname;
  final bool success;
  final Duration? latency;
  final int? httpStatus;
  final String? error;
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
