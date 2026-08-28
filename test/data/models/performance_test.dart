import 'package:chants/data/models/performance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  String state = 'approved',
  bool hidden = false,
  bool removed = false,
}) {
  final now = Timestamp.fromDate(DateTime.utc(2026, 8, 27));
  return {
    'schemaVersion': 1,
    'chantId': 'chant-1',
    'chantTitle': 'North London Forever',
    'teamId': 'arsenal',
    'teamName': 'Arsenal',
    'playerName': null,
    'chantStatus': 'canonical',
    'creatorId': 'creator-1',
    'creatorHandle': 'northbankleo',
    'creatorDisplayName': 'North Bank Leo',
    'caption': 'One take from the away end.',
    'mediaPath': 'performance-media/performance/source',
    'durationMs': 18000,
    'publicationState': state,
    'viewCount': 19,
    'likeCount': 7,
    'commentCount': 3,
    'shareCount': 4,
    'uniqueSharerCount': 4,
    'weeklyUniqueSharerCount': 4,
    'weeklyLikeCount': 7,
    'weeklyQualifiedViewCount': 12,
    'rankingWeek': '2026-08-24',
    'hidden': hidden,
    'removed': removed,
    'createdAt': now,
    'approvedAt': now,
    'updatedAt': now,
  };
}

void main() {
  test(
    'parses public performance and keeps trust separate from popularity',
    () {
      final performance = Performance.fromJson(_json(), id: 'performance-1');

      expect(performance.id, 'performance-1');
      expect(performance.isTerraceProven, isTrue);
      expect(performance.isVisible, isTrue);
      expect(performance.weeklyUniqueSharerCount, 4);
      expect(performance.likeCount, 7);
    },
  );

  test('hidden or removed approved performance is not visible', () {
    expect(
      Performance.fromJson(_json(hidden: true), id: 'hidden').isVisible,
      isFalse,
    );
    expect(
      Performance.fromJson(_json(removed: true), id: 'removed').isVisible,
      isFalse,
    );
  });

  test('unknown publication state fails closed', () {
    expect(
      () => Performance.fromJson(_json(state: 'pending'), id: 'pending'),
      throwsFormatException,
    );
  });

  test('missing counters use safe zero defaults', () {
    final json = _json()
      ..remove('viewCount')
      ..remove('likeCount')
      ..remove('commentCount')
      ..remove('shareCount')
      ..remove('uniqueSharerCount')
      ..remove('weeklyUniqueSharerCount')
      ..remove('weeklyLikeCount')
      ..remove('weeklyQualifiedViewCount');
    final performance = Performance.fromJson(json, id: 'legacy');

    expect(performance.viewCount, 0);
    expect(performance.weeklyUniqueSharerCount, 0);
  });
}
