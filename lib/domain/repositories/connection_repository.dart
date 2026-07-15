import '../../core/abstractions/result.dart';
import '../models/connection_status.dart';

/// Contract for reading current connection status. No implementation.
abstract interface class ConnectionRepository {
  Future<Result<ConnectionStatus>> getStatus();

  Stream<ConnectionStatus> watchStatus();
}
