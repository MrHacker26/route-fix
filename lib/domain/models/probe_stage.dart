/// Discrete stages of a network diagnostic probe.
enum ProbeStage {
  /// Hostname → address resolution.
  dns,

  /// TCP connect to a resolved address.
  tcp,

  /// TLS handshake (HTTPS only).
  tls,

  /// HTTP request / response status.
  http,
}
