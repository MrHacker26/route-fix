import '../../domain/models/connection_status.dart';

/// Observes connection status changes. Interface only.
abstract interface class ObserveConnectionUseCase {
  Stream<ConnectionStatus> call();
}
