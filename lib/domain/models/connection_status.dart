import 'health_score.dart';

/// Snapshot of local connectivity (domain shape only).
class ConnectionStatus {
  const ConnectionStatus({
    required this.isOnline,
    required this.interfaceName,
    required this.gateway,
    required this.dnsServers,
    required this.tone,
    this.ipv4Available = false,
    this.ipv6Available = false,
  });

  final bool isOnline;
  final String interfaceName;
  final String gateway;
  final List<String> dnsServers;
  final HealthTone tone;
  final bool ipv4Available;
  final bool ipv6Available;
}
