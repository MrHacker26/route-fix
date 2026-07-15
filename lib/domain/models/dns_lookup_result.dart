/// Result of resolving a hostname to address records.
class DnsLookupResult {
  const DnsLookupResult({
    required this.hostname,
    required this.ipv4Addresses,
    required this.ipv6Addresses,
    required this.lookupDuration,
  });

  final String hostname;
  final List<String> ipv4Addresses;
  final List<String> ipv6Addresses;
  final Duration lookupDuration;
}
