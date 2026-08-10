/// Encodes per-target DNS snapshots for restore after preset changes.
///
/// Keys are platform-specific targets (e.g. macOS service names). Values are
/// comma-separated IPv4 addresses, or [dhcpSentinel] when resolvers were DHCP.
abstract final class DnsBackupCodec {
  static const dhcpSentinel = 'dhcp';
  static const metadataKey = 'dns_backup';

  static String encode(Map<String, List<String>> backup) {
    if (backup.isEmpty) return '';
    return backup.entries
        .map((e) {
          final value = e.value.isEmpty ? dhcpSentinel : e.value.join(',');
          return '${_escape(e.key)}=${_escape(value)}';
        })
        .join(';');
  }

  static Map<String, List<String>> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    final out = <String, List<String>>{};
    for (final segment in raw.split(';')) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final key = _unescape(trimmed.substring(0, eq));
      final value = _unescape(trimmed.substring(eq + 1));
      if (key.isEmpty) continue;
      if (value == dhcpSentinel) {
        out[key] = const [];
      } else {
        out[key] = [
          for (final part in value.split(','))
            if (part.trim().isNotEmpty) part.trim(),
        ];
      }
    }
    return out;
  }

  static String _escape(String value) =>
      value.replaceAll('\\', r'\\').replaceAll('=', r'\=').replaceAll(';', r'\;');

  static String _unescape(String value) {
    final buffer = StringBuffer();
    var escaping = false;
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      if (escaping) {
        buffer.write(char);
        escaping = false;
      } else if (char == r'\') {
        escaping = true;
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
