/// Typed failure surface for domain and data layers.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

/// DNS resolution did not succeed.
final class DNSFailure extends AppFailure {
  const DNSFailure([super.message = 'DNS resolution failed']);
}

/// TCP connect did not succeed.
final class TCPFailure extends AppFailure {
  const TCPFailure([super.message = 'TCP connection failed']);
}

/// TLS handshake did not succeed.
final class TLSFailure extends AppFailure {
  const TLSFailure([super.message = 'TLS handshake failed']);
}

/// HTTP request failed or returned an unexpected status.
final class HTTPFailure extends AppFailure {
  const HTTPFailure(
    super.message, {
    this.statusCode,
  });

  final int? statusCode;
}

/// Operation exceeded its time budget.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.message = 'Operation timed out']);
}

/// Operation was cancelled before completion.
final class CancellationFailure extends AppFailure {
  const CancellationFailure([super.message = 'Operation cancelled']);
}

/// Failure that could not be classified more precisely.
final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unknown failure']);
}

/// Legacy name — prefer [CancellationFailure].
@Deprecated('Use CancellationFailure')
typedef CancelledFailure = CancellationFailure;

/// Legacy name — prefer [UnknownFailure].
@Deprecated('Use UnknownFailure')
typedef UnexpectedFailure = UnknownFailure;

/// Legacy catch-all — prefer a more specific [AppFailure] subtype.
@Deprecated('Use DNSFailure, TCPFailure, or UnknownFailure')
typedef UnavailableFailure = UnknownFailure;
