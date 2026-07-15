import '../../core/abstractions/result.dart';
import '../models/connection_status.dart';

/// Abstraction for observing device connectivity. No networking here.
abstract interface class ConnectivityService {
  Future<Result<ConnectionStatus>> current();

  Stream<ConnectionStatus> changes();
}
