import '../../core/abstractions/result.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/health_score.dart';
import '../../domain/models/scan_session.dart';

/// Aggregated dashboard view model shape.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.score,
    required this.connection,
    required this.latestScan,
  });

  final HealthScore score;
  final ConnectionStatus connection;
  final ScanSession? latestScan;
}

/// Loads the dashboard snapshot. Interface only.
abstract interface class GetDashboardSnapshotUseCase {
  Future<Result<DashboardSnapshot>> call();
}
