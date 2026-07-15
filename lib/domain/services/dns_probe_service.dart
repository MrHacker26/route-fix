import '../../core/abstractions/cancellable.dart';
import '../../core/abstractions/result.dart';
import '../models/diagnostic_check_result.dart';

/// Abstraction for DNS-oriented probes. Interface only — no network code.
abstract interface class DnsProbeService {
  Future<Result<DiagnosticCheckResult>> probe({
    required String resolverHint,
    CancellationToken? cancellationToken,
  });
}
