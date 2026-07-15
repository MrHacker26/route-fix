import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/abstractions/result.dart';
import 'package:route_fix/core/errors/app_failure.dart';
import 'package:route_fix/data/services/dns/dart_io_dns_lookup_service.dart';
import 'package:route_fix/domain/models/dns_lookup_result.dart';
import 'package:route_fix/domain/models/probe_stage.dart';

void main() {
  const service = DartIoDnsLookupService();

  test('rejects empty hostname', () async {
    final result = await service.lookup('   ');

    expect(result, isA<Failure<DnsLookupResult>>());
    final failure = result as Failure<DnsLookupResult>;
    expect(failure.error, isA<UnknownFailure>());
  });

  test('resolves localhost into addresses and duration', () async {
    final result = await service.lookup('localhost');

    expect(result, isA<Success<DnsLookupResult>>());
    final success = result as Success<DnsLookupResult>;
    final lookup = success.value;

    expect(lookup.hostname, 'localhost');
    expect(
      lookup.ipv4Addresses.isNotEmpty || lookup.ipv6Addresses.isNotEmpty,
      isTrue,
    );
    expect(lookup.lookupDuration >= Duration.zero, isTrue);
    expect(lookup.latency, lookup.lookupDuration);
    expect(lookup.stageReached, ProbeStage.dns);
    expect(lookup.stageFailed, isNull);
  });
}
