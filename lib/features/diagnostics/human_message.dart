/// Turns probe/OS noise into calm, human-readable copy.
abstract final class HumanMessage {
  static String fromProbeError(String? raw, {required String fallback}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final message = raw.trim();
    final lower = message.toLowerCase();

    if (lower.contains('no ipv6 address advertised') ||
        lower.contains('no ipv6 route advertised') ||
        lower.contains('no native ipv6')) {
      return 'No native IPv6 advertised.';
    }
    if (lower.contains('permission denied') || lower.contains('not permitted')) {
      return 'RouteFix needs administrator permission to continue.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'This check took too long and timed out.';
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('nodename nor servname') ||
        lower.contains('name or service not known')) {
      return 'We couldn’t look up that hostname.';
    }
    if (lower.contains('network is unreachable') ||
        lower.contains('no route to host')) {
      return 'We couldn’t reach that network path.';
    }
    if (lower.contains('connection refused')) {
      return 'The service didn’t accept the connection.';
    }
    if (lower.contains('socketexception') || lower.contains('http exception')) {
      return 'We couldn’t complete that connection attempt.';
    }
    if (lower.contains('unexpected http status')) {
      return 'The server answered, but not as expected.';
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
      'critical' => 'Needs Attention',
      'high' => 'Needs Attention',
      'medium' => 'Needs Attention',
      'low' => 'Ready',
      'info' => 'Ready',
      _ => raw,
    };
  }

  /// Labels how much a recommended fix might help a service.
  static String fixImpactLabel(String level) {
    return switch (level.toLowerCase()) {
      'high' => 'Likely improving',
      'medium' => 'May improve',
      'low' => 'Slight chance',
      'none' => 'Unaffected',
      _ => level,
    };
  }

  /// Labels how strongly a problem may be felt today (not fix optimism).
  static String feltImpactLabel(String level) {
    return switch (level.toLowerCase()) {
      'high' => 'Often affected',
      'medium' => 'Sometimes',
      'low' => 'Rarely',
      'none' => 'Unaffected',
      _ => level,
    };
  }

  /// @Deprecated Prefer [fixImpactLabel] or [feltImpactLabel].
  static String impactLabel(String level) => fixImpactLabel(level);

  /// Human confidence from an internal 0–1 value.
  static String confidenceStrength(double confidence) {
    if (confidence >= 0.85) return 'Strong';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  static String confidenceBadge(double confidence) {
    return switch (confidenceStrength(confidence)) {
      'Strong' => 'Strong evidence',
      'Medium' => 'Medium evidence',
      _ => 'Limited evidence',
    };
  }

  static String scoreBadge(int score) {
    if (score >= 75) return 'Healthy';
    if (score >= 55) return 'Needs Attention';
    return 'Needs Attention';
  }
}
