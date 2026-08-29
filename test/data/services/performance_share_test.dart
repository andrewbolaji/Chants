import 'dart:ui';

import 'package:chants/data/models/performance.dart';
import 'package:chants/data/services/performance_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

Performance _performance() {
  final now = DateTime.utc(2026, 8, 28);
  return Performance(
    id: 'performance-1',
    chantId: 'chant-1',
    chantTitle: 'Super Saka',
    teamId: 'arsenal',
    teamName: 'Arsenal',
    playerName: 'Bukayo Saka',
    chantStatus: 'community',
    creatorId: 'creator-private-id',
    creatorHandle: 'northbankleo',
    creatorDisplayName: 'North Bank Leo',
    caption: 'If this catches on, I am taking full credit.',
    mediaPath: 'performance-media/performance-1/source',
    durationMs: 18000,
    publicationState: PerformancePublicationState.approved,
    rankingWeek: '2026-08-24',
    createdAt: now,
    approvedAt: now,
    updatedAt: now,
  );
}

void main() {
  test('builds an honest public performance payload without private IDs', () {
    final payload = PerformanceSharePayload.fromPerformance(
      performance: _performance(),
      publicUrl: Uri.parse('https://chantsfc.com/performances/performance-1'),
    );

    expect(payload.text, contains('Super Saka'));
    expect(payload.text, contains('Bukayo Saka · Chant Lab idea'));
    expect(payload.text, contains('North Bank Leo (@northbankleo)'));
    expect(
      payload.text,
      contains('https://chantsfc.com/performances/performance-1'),
    );
    expect(payload.text, isNot(contains('creator-private-id')));
    expect(payload.text, isNot(contains('performance-media')));
  });

  test('rejects a noncanonical public destination', () {
    expect(
      () => PerformanceSharePayload.fromPerformance(
        performance: _performance(),
        publicUrl: Uri.parse('https://example.com/performances/one'),
      ),
      throwsArgumentError,
    );
  });

  test(
    'counts success and unavailable results but not a dismissed sheet',
    () async {
      const origin = Rect.fromLTWH(1, 1, 48, 48);
      final payload = PerformanceSharePayload.fromPerformance(
        performance: _performance(),
        publicUrl: Uri.parse('https://chantsfc.com/performances/performance-1'),
      );
      for (final entry in const [
        (ShareResult('messages', ShareResultStatus.success), true),
        (ShareResult.unavailable, true),
        (ShareResult('', ShareResultStatus.dismissed), false),
      ]) {
        final gateway = PlatformPerformanceShareGateway(
          platformCall: (_) async => entry.$1,
        );
        expect(
          await gateway.share(payload, sharePositionOrigin: origin),
          entry.$2,
        );
      }
    },
  );
}
