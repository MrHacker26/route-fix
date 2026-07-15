/// Outcome of an IPv4 connectivity check against a hostname.
class Ipv4ConnectivityResult {
  const Ipv4ConnectivityResult({
    required this.success,
    this.latency,
    this.error,
    this.resolvedAddress,
  });

  final bool success;
  final Duration? latency;
  final String? error;
  final String? resolvedAddress;
}
