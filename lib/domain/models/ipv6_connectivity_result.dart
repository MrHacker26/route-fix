/// Outcome of an IPv6 connectivity check against a hostname.
class Ipv6ConnectivityResult {
  const Ipv6ConnectivityResult({
    required this.success,
    this.latency,
    this.resolvedAddress,
    this.error,
  });

  final bool success;
  final Duration? latency;
  final String? resolvedAddress;
  final String? error;
}
