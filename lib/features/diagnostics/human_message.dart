/// Turns probe/OS noise into calm, human-readable copy.
abstract final class HumanMessage {
  static String fromProbeError(String? raw, {required String fallback}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final message = raw.trim();
    final lower = message.toLowerCase();

    if (lower.contains('permission denied') || lower.contains('not permitted')) {
      return 'RouteFix needs administrator permission to continue.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'This check took too long and timed out.';
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('nodename nor servname') ||
        lower.contains('name or service not known')) {
      return 'Couldn’t look up that hostname right now.';
    }
    if (lower.contains('network is unreachable') ||
        lower.contains('no route to host')) {
      return 'Your device couldn’t reach that network path.';
    }
    if (lower.contains('connection refused')) {
      return 'The service refused the connection.';
    }
    if (lower.contains('socketexception') || lower.contains('http exception')) {
      return 'A connection attempt didn’t complete successfully.';
    }
    if (lower.contains('unexpected http status')) {
      return 'The server responded, but not in the way we expected.';
    }
    if (message.length > 140 ||
        lower.contains('exception') ||
        lower.contains('error:') ||
        RegExp(r'0x[0-9a-f]+', caseSensitive: false).hasMatch(message)) {
      return fallback;
    }
    return message;
  }

  static String severityLabel(String raw) {
    return switch (raw.toLowerCase()) {
      'critical' => 'Urgent',
      'high' => 'Important',
      'medium' => 'Noticeable',
      'low' => 'Minor',
      'info' => 'Info',
      _ => raw,
    };
  }

  static String impactLabel(String level) {
    return switch (level.toLowerCase()) {
      'high' => 'Likely improving',
      'medium' => 'May improve',
      'low' => 'Slight chance',
      'none' => 'Unaffected',
      _ => level,
    };
  }
}
