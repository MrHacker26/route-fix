import 'dart:io';

import '../../../core/errors/app_failure.dart';

/// Maps low-level I/O errors to structured [AppFailure] values.
abstract final class ProbeFailureMapper {
  static AppFailure fromSocketException(
    SocketException error, {
    required ProbeSocketStage stage,
  }) {
    final message = error.message.trim().isEmpty
        ? _defaultMessage(stage)
        : error.message.trim();
    final lower = message.toLowerCase();

    if (_looksLikeDns(lower) || stage == ProbeSocketStage.dns) {
      return DNSFailure(message);
    }
    return TCPFailure(message);
  }

  static AppFailure fromTimeout({
    required String message,
  }) {
    return TimeoutFailure(message);
  }

  static AppFailure fromHandshake(HandshakeException error) {
    final message =
        error.message.trim().isEmpty ? 'TLS handshake failed' : error.message;
    return TLSFailure(message);
  }

  static AppFailure fromHttpException(HttpException error) {
    final message =
        error.message.trim().isEmpty ? 'HTTP request failed' : error.message;
    return HTTPFailure(message);
  }

  static AppFailure unexpectedHttpStatus(int status) {
    return HTTPFailure(
      'Unexpected HTTP status $status',
      statusCode: status,
    );
  }

  static AppFailure unknown(Object error) {
    return UnknownFailure(error.toString());
  }

  static bool _looksLikeDns(String lower) {
    return lower.contains('failed host lookup') ||
        lower.contains('name or service not known') ||
        lower.contains('nodename nor servname') ||
        lower.contains('temporary failure in name resolution') ||
        lower.contains('no address associated with hostname');
  }

  static String _defaultMessage(ProbeSocketStage stage) {
    return switch (stage) {
      ProbeSocketStage.dns => 'DNS resolution failed',
      ProbeSocketStage.tcp => 'TCP connection failed',
    };
  }
}

/// Which connection stage produced a [SocketException].
enum ProbeSocketStage {
  dns,
  tcp,
}
