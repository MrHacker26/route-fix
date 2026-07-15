/// Domain layer — models, repository contracts, service contracts.
library;

export 'models/connection_status.dart';
export 'models/diagnostic_check_result.dart';
export 'models/diagnostic_target.dart';
export 'models/dns_lookup_result.dart';
export 'models/health_score.dart';
export 'models/issue.dart';
export 'models/latency_sample.dart';
export 'models/recommendation.dart';
export 'models/scan_session.dart';
export 'repositories/connection_repository.dart';
export 'repositories/diagnostics_repository.dart';
export 'repositories/scan_history_repository.dart';
export 'repositories/settings_repository.dart';
export 'services/connectivity_service.dart';
export 'services/dns_lookup_service.dart';
export 'services/dns_probe_service.dart';
export 'services/health_scoring_service.dart';
export 'services/latency_probe_service.dart';
export 'services/route_analysis_service.dart';
