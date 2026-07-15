/// Typed failure surface for domain and data layers.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Unexpected failure']);
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure([super.message = 'Operation cancelled']);
}

final class UnavailableFailure extends AppFailure {
  const UnavailableFailure([super.message = 'Capability unavailable']);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.message = 'Operation timed out']);
}
