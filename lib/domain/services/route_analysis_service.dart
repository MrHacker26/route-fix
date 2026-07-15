import '../../core/abstractions/result.dart';
import '../models/diagnostic_check_result.dart';
import '../models/issue.dart';
import '../models/recommendation.dart';

/// Abstraction for turning check results into issues + recommendations.
abstract interface class RouteAnalysisService {
  Future<Result<RouteAnalysis>> analyze(List<DiagnosticCheckResult> checks);
}

class RouteAnalysis {
  const RouteAnalysis({
    required this.issues,
    required this.recommendations,
  });

  final List<Issue> issues;
  final List<Recommendation> recommendations;
}
