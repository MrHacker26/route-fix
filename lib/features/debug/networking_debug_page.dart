import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Temporary networking-layer debug page.
///
/// Runs each step independently against [host] and prints raw results.
/// No classification, no recommendations, no architecture changes.
class NetworkingDebugPage extends StatefulWidget {
  const NetworkingDebugPage({
    super.key,
    this.host = 'github.com',
    this.port = 443,
  });

  final String host;
  final int port;

  @override
  State<NetworkingDebugPage> createState() => _NetworkingDebugPageState();
}

class _NetworkingDebugPageState extends State<NetworkingDebugPage> {
  final StringBuffer _log = StringBuffer();
  var _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAll());
    });
  }

  void _append(String line) {
    debugPrint(line);
    if (!mounted) return;
    setState(() {
      _log.writeln(line);
    });
  }

  Future<void> _runAll() async {
    if (_running) return;
    setState(() {
      _running = true;
      _log.clear();
    });

    final host = widget.host;
    final port = widget.port;

    _append('=== Networking debug: $host:$port ===');
    _append('Started: ${DateTime.now().toIso8601String()}');
    _append('');

    await _stepDns(host);
    _append('');
    await _stepIpv4Tcp(host, port);
    _append('');
    await _stepIpv6Tcp(host, port);
    _append('');
    await _stepTls(host, port);
    _append('');
    await _stepHttpsGet(host, port);

    _append('');
    _append('=== Done: ${DateTime.now().toIso8601String()} ===');

    if (mounted) {
      setState(() => _running = false);
    }
  }

  Future<void> _stepDns(String host) async {
    _append('--- 1. DNS lookup ---');
    try {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isEmpty) {
        _append('No addresses returned.');
        return;
      }

      final ipv4 = addresses
          .where((a) => a.type == InternetAddressType.IPv4)
          .toList(growable: false);
      final ipv6 = addresses
          .where((a) => a.type == InternetAddressType.IPv6)
          .toList(growable: false);

      _append('Resolved ${addresses.length} address(es).');
      _append('IPv4 (${ipv4.length}):');
      if (ipv4.isEmpty) {
        _append('  (none)');
      } else {
        for (final a in ipv4) {
          _append('  ${a.address}');
        }
      }
      _append('IPv6 (${ipv6.length}):');
      if (ipv6.isEmpty) {
        _append('  (none)');
      } else {
        for (final a in ipv6) {
          _append('  ${a.address}');
        }
      }
    } catch (error, stack) {
      _append('EXCEPTION: $error');
      _append(stack.toString());
    }
  }

  Future<void> _stepIpv4Tcp(String host, int port) async {
    _append('--- 2. IPv4 TCP connect ---');
    Socket? socket;
    try {
      final addresses = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv4,
      );
      final ipv4 = addresses
          .where((a) => a.type == InternetAddressType.IPv4)
          .toList(growable: false);
      if (ipv4.isEmpty) {
        _append('No IPv4 addresses to connect to.');
        return;
      }

      final target = ipv4.first;
      _append('Connecting to ${target.address}:$port …');
      socket = await Socket.connect(
        target,
        port,
        timeout: const Duration(seconds: 8),
      );
      _append('SUCCESS remote=${socket.remoteAddress.address}:'
          '${socket.remotePort} local=${socket.address.address}:'
          '${socket.port}');
    } catch (error, stack) {
      _append('EXCEPTION: $error');
      _append(stack.toString());
    } finally {
      await _closeQuietly(socket);
    }
  }

  Future<void> _stepIpv6Tcp(String host, int port) async {
    _append('--- 3. IPv6 TCP connect ---');
    Socket? socket;
    try {
      final addresses = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv6,
      );
      final ipv6 = addresses
          .where((a) => a.type == InternetAddressType.IPv6)
          .toList(growable: false);
      if (ipv6.isEmpty) {
        _append('No IPv6 addresses to connect to.');
        return;
      }

      final target = ipv6.first;
      _append('Connecting to [${target.address}]:$port …');
      socket = await Socket.connect(
        target,
        port,
        timeout: const Duration(seconds: 8),
      );
      _append('SUCCESS remote=${socket.remoteAddress.address}:'
          '${socket.remotePort} local=${socket.address.address}:'
          '${socket.port}');
    } catch (error, stack) {
      _append('EXCEPTION: $error');
      _append(stack.toString());
    } finally {
      await _closeQuietly(socket);
    }
  }

  Future<void> _stepTls(String host, int port) async {
    _append('--- 4. TLS handshake ---');
    Socket? raw;
    SecureSocket? secure;
    try {
      _append('TCP connect to $host:$port …');
      raw = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 8),
      );
      _append('TCP connected. Starting TLS (SNI=$host) …');
      secure = await SecureSocket.secure(
        raw,
        host: host,
      ).timeout(const Duration(seconds: 8));
      raw = null; // owned by SecureSocket
      _append(
        'SUCCESS protocol=${secure.selectedProtocol ?? '(none)'} '
        'peer=${secure.peerCertificate?.subject ?? '(no cert)'}',
      );
    } catch (error, stack) {
      _append('EXCEPTION: $error');
      _append(stack.toString());
    } finally {
      await _closeQuietly(secure ?? raw);
    }
  }

  Future<void> _stepHttpsGet(String host, int port) async {
    _append('--- 5. HTTPS GET ---');
    Socket? raw;
    SecureSocket? secure;
    try {
      raw = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 8),
      );
      secure = await SecureSocket.secure(
        raw,
        host: host,
      ).timeout(const Duration(seconds: 8));
      raw = null;

      final request = 'GET / HTTP/1.1\r\n'
          'Host: $host\r\n'
          'User-Agent: RouteFix-NetworkingDebug/1.0\r\n'
          'Accept: */*\r\n'
          'Connection: close\r\n'
          '\r\n';
      secure.add(utf8.encode(request));
      await secure.flush().timeout(const Duration(seconds: 8));

      final statusLine = await _readStatusLine(secure)
          .timeout(const Duration(seconds: 8));
      _append('Status line: $statusLine');

      final parts = statusLine.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        _append('Status code: ${parts[1]}');
      } else {
        _append('Status code: (could not parse)');
      }
    } catch (error, stack) {
      _append('EXCEPTION: $error');
      _append(stack.toString());
    } finally {
      await _closeQuietly(secure ?? raw);
    }
  }

  Future<String> _readStatusLine(Socket transport) async {
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in transport) {
      buffer.add(chunk);
      final bytes = buffer.toBytes();
      for (var i = 0; i < bytes.length - 1; i++) {
        if (bytes[i] == 13 && bytes[i + 1] == 10) {
          return utf8.decode(bytes.sublist(0, i));
        }
      }
      if (bytes.length > 8192) {
        throw const HttpException('Status line too long');
      }
    }
    throw const HttpException('Connection closed before status line');
  }

  Future<void> _closeQuietly(Socket? socket) async {
    if (socket == null) return;
    try {
      await socket.close();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      appBar: AppBar(
        title: Text('Networking debug · ${widget.host}'),
        backgroundColor: const Color(0xFF1C1C1F),
        actions: [
          TextButton(
            onPressed: _running ? null : () => unawaited(_runAll()),
            child: const Text('Re-run'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_running)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _log.isEmpty ? 'Waiting…' : _log.toString(),
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontFamilyFallback: ['monospace'],
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFFE8E8EA),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
