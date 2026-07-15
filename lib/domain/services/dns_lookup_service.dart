import '../../core/abstractions/result.dart';
import '../models/dns_lookup_result.dart';

/// Resolves a hostname to IPv4 / IPv6 addresses.
///
/// Lookup only — no diagnosis or scoring.
abstract interface class DnsLookupService {
  Future<Result<DnsLookupResult>> lookup(String hostname);
}
