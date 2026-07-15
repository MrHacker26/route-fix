import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/errors/app_failure.dart';
import '../../../domain/models/http_probe_result.dart';
import '../../../domain/models/probe_stage.dart';
import '../../../domain/models/probe_timings.dart';
import '../../../domain/services/http_probe_service.dart';
import '../probe_failure_mapper.dart';

/// Generic HTTP(S) probe with explicit DNS → TCP → TLS → HTTP timings.
class DartIoHttpProbeService implements HttpProbeService {
  const DartIoHttpProbeService();

  @override
  Future<HttpProbeResult> probe(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!(uri.isScheme('http') || uri.isScheme('https'))) {
      return const HttpProbeResult(
        success: false,
        failure: UnknownFailure('URI must use http or https'),
      );
    }

    final host = uri.host.trim();
    if (host.isEmpty) {
      return const HttpProbeResult(
        success: false,
        failure: UnknownFailure('URI host must not be empty'),
      );
    }

    final useTls = uri.isScheme('https');
    final port = uri.port;
    var timings = ProbeTimings.empty;

    // --- DNS ---
    final dnsWatch = Stopwatch()..start();
    late final InternetAddress address;
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      if (addresses.isEmpty) {
        return _fail(
          timings: timings,
          stageFailed: ProbeStage.dns,
          failure: DNSFailure('No addresses found for "$host"'),
        );
      }
      address = addresses.first;
    } on TimeoutException {
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      return _fail(
        timings: timings,
        stageFailed: ProbeStage.dns,
        failure: const TimeoutFailure('DNS lookup timed out'),
      );
    } on SocketException catch (error) {
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      return _fail(
        timings: timings,
        stageFailed: ProbeStage.dns,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.dns,
        ),
      );
    } catch (error) {
      dnsWatch.stop();
      timings = timings.copyWith(dns: dnsWatch.elapsed);
      return _fail(
        timings: timings,
        stageFailed: ProbeStage.dns,
        failure: ProbeFailureMapper.unknown(error),
      );
    }

    // --- TCP ---
    final tcpWatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(address, port, timeout: timeout);
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
    } on TimeoutException {
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
      return _fail(
        timings: timings,
        stageReached: ProbeStage.dns,
        stageFailed: ProbeStage.tcp,
        failure: const TimeoutFailure('TCP connect timed out'),
      );
    } on SocketException catch (error) {
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
      return _fail(
        timings: timings,
        stageReached: ProbeStage.dns,
        stageFailed: ProbeStage.tcp,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.tcp,
        ),
      );
    } catch (error) {
      tcpWatch.stop();
      timings = timings.copyWith(tcp: tcpWatch.elapsed);
      await socket?.close();
      return _fail(
        timings: timings,
        stageReached: ProbeStage.dns,
        stageFailed: ProbeStage.tcp,
        failure: ProbeFailureMapper.unknown(error),
      );
    }

    // --- TLS (HTTPS only) ---
    Socket transport = socket;
    ProbeStage stageReached = ProbeStage.tcp;

    if (useTls) {
      final tlsWatch = Stopwatch()..start();
      try {
        transport = await SecureSocket.secure(
          socket,
          host: host,
        ).timeout(timeout);
        tlsWatch.stop();
        timings = timings.copyWith(tls: tlsWatch.elapsed);
        stageReached = ProbeStage.tls;
        socket = null; // owned by SecureSocket
      } on TimeoutException {
        tlsWatch.stop();
        timings = timings.copyWith(tls: tlsWatch.elapsed);
        await _closeQuietly(socket);
        return _fail(
          timings: timings,
          stageReached: ProbeStage.tcp,
          stageFailed: ProbeStage.tls,
          failure: const TimeoutFailure('TLS handshake timed out'),
        );
      } on HandshakeException catch (error) {
        tlsWatch.stop();
        timings = timings.copyWith(tls: tlsWatch.elapsed);
        await _closeQuietly(socket);
        return _fail(
          timings: timings,
          stageReached: ProbeStage.tcp,
          stageFailed: ProbeStage.tls,
          failure: ProbeFailureMapper.fromHandshake(error),
        );
      } on SocketException catch (error) {
        tlsWatch.stop();
        timings = timings.copyWith(tls: tlsWatch.elapsed);
        await _closeQuietly(socket);
        return _fail(
          timings: timings,
          stageReached: ProbeStage.tcp,
          stageFailed: ProbeStage.tls,
          failure: ProbeFailureMapper.fromSocketException(
            error,
            stage: ProbeStage.tls,
          ),
        );
      } on TlsException catch (error) {
        tlsWatch.stop();
        timings = timings.copyWith(tls: tlsWatch.elapsed);
        await _closeQuietly(socket);
        return _fail(
          timings: timings,
          stageReached: ProbeStage.tcp,
          stageFailed: ProbeStage.tls,
          failure: TLSFailure(
            error.message.trim().isEmpty
                ? 'TLS handshake failed'
                : error.message,
          ),
        );
      } catch (error) {
        tlsWatch.stop();
        timings = timings.copyWith(tls: tlsWatch.elapsed);
        await _closeQuietly(socket);
        return _fail(
          timings: timings,
          stageReached: ProbeStage.tcp,
          stageFailed: ProbeStage.tls,
          failure: ProbeFailureMapper.unknown(error),
        );
      }
    }

    // --- HTTP ---
    final httpWatch = Stopwatch()..start();
    try {
      final status = await _exchangeHttpStatus(
        transport,
        uri: uri,
        host: host,
        timeout: timeout,
      );
      httpWatch.stop();
      timings = timings.copyWith(http: httpWatch.elapsed);

      final ok = status >= 200 && status < 400;
      return HttpProbeResult(
        success: ok,
        latency: timings.http,
        httpStatus: status,
        stageReached: ProbeStage.http,
        stageFailed: ok ? null : ProbeStage.http,
        failure: ok ? null : ProbeFailureMapper.unexpectedHttpStatus(status),
        timings: timings,
      );
    } on TimeoutException {
      httpWatch.stop();
      timings = timings.copyWith(http: httpWatch.elapsed);
      return _fail(
        timings: timings,
        stageReached: stageReached,
        stageFailed: ProbeStage.http,
        failure: const TimeoutFailure('HTTP probe timed out'),
      );
    } on HttpException catch (error) {
      httpWatch.stop();
      timings = timings.copyWith(http: httpWatch.elapsed);
      return _fail(
        timings: timings,
        stageReached: stageReached,
        stageFailed: ProbeStage.http,
        failure: ProbeFailureMapper.fromHttpException(error),
      );
    } on SocketException catch (error) {
      httpWatch.stop();
      timings = timings.copyWith(http: httpWatch.elapsed);
      return _fail(
        timings: timings,
        stageReached: stageReached,
        stageFailed: ProbeStage.http,
        failure: ProbeFailureMapper.fromSocketException(
          error,
          stage: ProbeStage.http,
        ),
      );
    } catch (error) {
      httpWatch.stop();
      timings = timings.copyWith(http: httpWatch.elapsed);
      return _fail(
        timings: timings,
        stageReached: stageReached,
        stageFailed: ProbeStage.http,
        failure: ProbeFailureMapper.unknown(error),
      );
    } finally {
      await _closeQuietly(transport);
    }
  }

  HttpProbeResult _fail({
    required ProbeTimings timings,
    required ProbeStage stageFailed,
    required AppFailure failure,
    ProbeStage? stageReached,
  }) {
    return HttpProbeResult(
      success: false,
      latency: timings.terminal,
      stageReached: stageReached,
      stageFailed: stageFailed,
      failure: failure,
      timings: timings,
    );
  }

  Future<int> _exchangeHttpStatus(
    Socket transport, {
    required Uri uri,
    required String host,
    required Duration timeout,
  }) async {
    final path = _requestTarget(uri);
    final request = 'GET $path HTTP/1.1\r\n'
        'Host: $host\r\n'
        'User-Agent: RouteFix/1.0\r\n'
        'Accept: */*\r\n'
        'Connection: close\r\n'
        '\r\n';

    transport.add(utf8.encode(request));
    await transport.flush().timeout(timeout);

    final statusLine = await _readStatusLine(transport).timeout(timeout);
    return _parseStatusCode(statusLine);
  }

  Future<String> _readStatusLine(Socket transport) async {
    final buffer = BytesBuilder(copy: false);

    await for (final chunk in transport) {
      buffer.add(chunk);
      final bytes = buffer.toBytes();
      final end = _indexOfCrlf(bytes);
      if (end >= 0) {
        return utf8.decode(bytes.sublist(0, end));
      }
      if (bytes.length > 8192) {
        throw const HttpException('HTTP status line too long');
      }
    }

    throw const HttpException('Connection closed before HTTP status');
  }

  int _indexOfCrlf(Uint8List bytes) {
    for (var i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 13 && bytes[i + 1] == 10) {
        return i;
      }
    }
    return -1;
  }

  int _parseStatusCode(String statusLine) {
    final parts = statusLine.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      throw HttpException('Invalid HTTP status line: $statusLine');
    }
    final code = int.tryParse(parts[1]);
    if (code == null) {
      throw HttpException('Invalid HTTP status code: $statusLine');
    }
    return code;
  }

  String _requestTarget(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    if (uri.hasQuery) {
      return '$path?${uri.query}';
    }
    return path;
  }

  Future<void> _closeQuietly(Socket? socket) async {
    if (socket == null) {
      return;
    }
    try {
      await socket.close();
    } catch (_) {
      // Ignore close errors after a failed probe stage.
    }
  }
}
