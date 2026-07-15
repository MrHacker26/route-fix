import 'probe_stage.dart';

/// Result of resolving a hostname to address records.
class DnsLookupResult {
  const DnsLookupResult({
    required this.hostname,
    required this.ipv4Addresses,
    required this.ipv6Addresses,
    required this.lookupDuration,
    this.stageReached = ProbeStage.dns,
    this.stageFailed,
  });

  final String hostname;
  final List<String> ipv4Addresses;
  final List<String> ipv6Addresses;

  /// Wall time for the DNS stage (also exposed as [latency]).
  final Duration lookupDuration;

  /// Last stage that completed successfully (null if none).
  final ProbeStage? stageReached;

  /// Stage where resolution stopped with a failure (null on success).
  final ProbeStage? stageFailed;

  /// Alias for [lookupDuration] for the shared probe result shape.
  Duration get latency => lookupDuration;
}
