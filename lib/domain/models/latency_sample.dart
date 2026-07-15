/// A single latency observation for charts and history.
class LatencySample {
  const LatencySample({
    required this.targetId,
    required this.recordedAt,
    required this.duration,
  });

  final String targetId;
  final DateTime recordedAt;
  final Duration duration;
}
