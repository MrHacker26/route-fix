/// Token that signals cooperative cancellation to long-running work.
abstract interface class CancellationToken {
  bool get isCancelled;

  void cancel();
}
