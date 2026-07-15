import '../../core/abstractions/cancellable.dart';
import '../../core/abstractions/result.dart';
import '../models/diagnostic_check_result.dart';
import '../models/diagnostic_target.dart';

/// Abstraction for latency probes to a target. Interface only.
abstract interface class LatencyProbeService {
  Future<Result<DiagnosticCheckResult>> probe({
    required DiagnosticTarget target,
    CancellationToken? cancellationToken,
  });
}
