import '../../core/abstractions/cancellable.dart';
import '../../core/abstractions/result.dart';
import '../models/diagnostic_check_result.dart';
import '../models/diagnostic_target.dart';
import '../models/scan_session.dart';

/// Contract for running and observing diagnostics. No implementation.
abstract interface class DiagnosticsRepository {
  Future<Result<ScanSession>> startScan({
    required List<DiagnosticTarget> targets,
    CancellationToken? cancellationToken,
  });

  Stream<DiagnosticCheckResult> watchCheckProgress(String sessionId);

  Future<Result<ScanSession>> getSession(String sessionId);

  Future<Result<void>> cancelScan(String sessionId);
}
