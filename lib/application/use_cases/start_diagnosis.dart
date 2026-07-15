import '../../core/abstractions/cancellable.dart';
import '../../core/abstractions/result.dart';
import '../../domain/models/diagnostic_check_result.dart';
import '../../domain/models/diagnostic_target.dart';
import '../../domain/models/scan_session.dart';

/// Starts a diagnosis session and exposes progress. Interface only.
abstract interface class StartDiagnosisUseCase {
  Future<Result<ScanSession>> call({
    required List<DiagnosticTarget> targets,
    CancellationToken? cancellationToken,
  });

  Stream<DiagnosticCheckResult> progress(String sessionId);
}
