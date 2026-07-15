import '../../core/abstractions/result.dart';
import '../models/diagnostic_check_result.dart';
import '../models/health_score.dart';

/// Abstraction for computing an overall health score from checks.
abstract interface class HealthScoringService {
  Future<Result<HealthScore>> score(List<DiagnosticCheckResult> checks);
}
