import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/probe_failure_mapper.dart';

void main() {
  group('ProbeFailureMapper', () {
    test('maps host-lookup sockets to DNSFailure', () {
      final failure = ProbeFailureMapper.fromSocketException(
        const SocketException('Failed host lookup: example.com'),
        stage: ProbeSocketStage.tcp,
      );

      expect(failure, isA<DNSFailure>());
    });

    test('maps connect sockets to TCPFailure', () {
      final failure = ProbeFailureMapper.fromSocketException(
        const SocketException('Connection refused'),
        stage: ProbeSocketStage.tcp,
      );

      expect(failure, isA<TCPFailure>());
    });

    test('maps handshake errors to TLSFailure', () {
      final failure = ProbeFailureMapper.fromHandshake(
        const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
      );

      expect(failure, isA<TLSFailure>());
    });

    test('maps unexpected statuses to HTTPFailure', () {
      final failure = ProbeFailureMapper.unexpectedHttpStatus(503);

      expect(failure, isA<HTTPFailure>());
      expect((failure as HTTPFailure).statusCode, 503);
    });

    test('maps timeouts to TimeoutFailure', () {
      expect(
        ProbeFailureMapper.fromTimeout(message: 'timed out'),
        isA<TimeoutFailure>(),
      );
    });
  });
}
