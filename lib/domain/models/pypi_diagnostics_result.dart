import '../../core/errors/app_failure.dart';
import 'probe_stage.dart';
import 'probe_timings.dart';

/// HTTP probe outcome tagged with the target hostname.
class HostHttpProbeResult {
  const HostHttpProbeResult({
    required this.hostname,
    required this.success,
    this.latency,
    this.httpStatus,
    this.failure,
    this.stageReached,
    this.stageFailed,
    this.timings = ProbeTimings.empty,
  });

  final String hostname;
  final bool success;
  final Duration? latency;
  final int? httpStatus;
  final AppFailure? failure;
  final ProbeStage? stageReached;
  final ProbeStage? stageFailed;
  final ProbeTimings timings;

  /// Message form of [failure] for existing call sites.
  String? get error => failure?.message;
}

/// Combined PyPI index + files host probe results.
class PypiDiagnosticsResult {
  const PypiDiagnosticsResult({
    required this.index,
    required this.files,
  });

  final HostHttpProbeResult index;
  final HostHttpProbeResult files;

  bool get success => index.success && files.success;

  List<HostHttpProbeResult> get targets => [index, files];
}
