import '../../core/abstractions/result.dart';
import '../../domain/models/scan_session.dart';

/// Loads a completed scan result. Interface only.
abstract interface class GetScanResultUseCase {
  Future<Result<ScanSession>> call(String sessionId);
}
