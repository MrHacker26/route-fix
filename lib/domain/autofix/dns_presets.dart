/// Well-known public DNS presets for Auto Fix.
abstract final class DnsPresets {
  static const cloudflarePrimary = '1.1.1.1';
  static const cloudflareSecondary = '1.0.0.1';

  static const List<String> cloudflare = [
    cloudflarePrimary,
    cloudflareSecondary,
  ];

  static bool isCloudflareServers(Iterable<String> servers) {
    final normalized = servers.map((s) => s.trim()).where((s) => s.isNotEmpty);
    final set = normalized.toSet();
    return set.contains(cloudflarePrimary) &&
        set.contains(cloudflareSecondary) &&
        set.length == 2;
  }
}
