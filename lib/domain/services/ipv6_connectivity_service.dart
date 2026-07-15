import '../models/ipv6_connectivity_result.dart';

/// Checks IPv6 reachability for a hostname.
///
/// Connectivity only — no diagnosis or scoring.
abstract interface class Ipv6ConnectivityService {
  /// Probes [hostname] over IPv6 (TCP connect to [port], default 443).
  Future<Ipv6ConnectivityResult> check(
    String hostname, {
    int port = 443,
  });
}
