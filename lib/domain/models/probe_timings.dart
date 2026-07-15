/// Wall-clock measurements for discrete probe stages.
///
/// Each field is the elapsed time for that stage alone (not cumulative).
/// Stages that never ran remain null.
final class ProbeTimings {
  const ProbeTimings({
    this.dns,
    this.tcp,
    this.tls,
    this.http,
  });

  static const empty = ProbeTimings();

  /// DNS lookup duration.
  final Duration? dns;

  /// TCP connect duration.
  final Duration? tcp;

  /// TLS handshake duration (HTTPS only).
  final Duration? tls;

  /// HTTP request through status-line duration (body not included).
  final Duration? http;

  /// Last completed stage measurement (http → tls → tcp → dns).
  Duration? get terminal => http ?? tls ?? tcp ?? dns;

  ProbeTimings copyWith({
    Duration? dns,
    Duration? tcp,
    Duration? tls,
    Duration? http,
  }) {
    return ProbeTimings(
      dns: dns ?? this.dns,
      tcp: tcp ?? this.tcp,
      tls: tls ?? this.tls,
      http: http ?? this.http,
    );
  }

  /// Flat metadata keys like `cloudflare_dns_ms`.
  Map<String, String> toMetadata(String prefix) {
    return {
      if (dns != null) '${prefix}_dns_ms': '${dns!.inMilliseconds}',
      if (tcp != null) '${prefix}_tcp_ms': '${tcp!.inMilliseconds}',
      if (tls != null) '${prefix}_tls_ms': '${tls!.inMilliseconds}',
      if (http != null) '${prefix}_http_ms': '${http!.inMilliseconds}',
    };
  }
}
