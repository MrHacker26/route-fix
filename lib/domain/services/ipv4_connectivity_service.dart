import '../models/ipv4_connectivity_result.dart';

/// Checks IPv4 reachability for a hostname.
///
/// Connectivity only — no diagnosis or scoring.
abstract interface class Ipv4ConnectivityService {
  /// Probes [hostname] over IPv4 (TCP connect to [port], default 443).
  Future<Ipv4ConnectivityResult> check(
    String hostname, {
    int port = 443,
  });
}
