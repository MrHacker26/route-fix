import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/data/autofix/dns/dns_backup_codec.dart';

void main() {
  test('encodes and decodes DHCP and static servers', () {
    final raw = DnsBackupCodec.encode({
      'Wi-Fi': const [],
      'Ethernet': const ['8.8.8.8', '8.8.4.4'],
    });

    final decoded = DnsBackupCodec.decode(raw);
    expect(decoded['Wi-Fi'], isEmpty);
    expect(decoded['Ethernet'], ['8.8.8.8', '8.8.4.4']);
  });
}
