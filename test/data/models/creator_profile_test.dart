import 'package:chants/data/models/creator_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creator profile parses only public identity and aggregate fields', () {
    final now = DateTime(2026, 8, 27, 18, 30);
    final profile = CreatorProfile.fromJson({
      'handle': 'northbankleo',
      'displayName': 'North Bank Leo',
      'bio': 'Arsenal and away ends.',
      'followerCount': 12,
      'followingCount': 4,
      'performanceCount': 3,
      'likeCount': 99,
      'shareCount': 18,
      'hidden': false,
      'removed': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, id: 'fan');

    expect(profile.id, 'fan');
    expect(profile.handle, 'northbankleo');
    expect(profile.displayName, 'North Bank Leo');
    expect(profile.bio, 'Arsenal and away ends.');
    expect(profile.followerCount, 12);
    expect(profile.followingCount, 4);
    expect(profile.performanceCount, 3);
    expect(profile.likeCount, 99);
    expect(profile.shareCount, 18);
    expect(profile.hidden, false);
    expect(profile.removed, false);
    expect(profile.createdAt, now);
    expect(profile.updatedAt, now);
  });

  test(
    'legacy-safe optional public fields default without inventing identity',
    () {
      final now = DateTime(2026, 8, 27);
      final profile = CreatorProfile.fromJson({
        'handle': 'clockend',
        'displayName': 'Clock End',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, id: 'fan');

      expect(profile.bio, '');
      expect(profile.followerCount, 0);
      expect(profile.followingCount, 0);
      expect(profile.performanceCount, 0);
      expect(profile.likeCount, 0);
      expect(profile.shareCount, 0);
      expect(profile.hidden, false);
      expect(profile.removed, false);
    },
  );
}
