import '../../core/abstractions/result.dart';
import '../models/scan_session.dart';

/// Contract for persisted scan history. No implementation.
abstract interface class ScanHistoryRepository {
  Future<Result<List<ScanSession>>> listRecent({int limit = 10});

  Future<Result<ScanSession?>> getLatest();

  Future<Result<void>> save(ScanSession session);

  Future<Result<void>> clear();
}
