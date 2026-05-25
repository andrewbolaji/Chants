import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/chant.dart';

void main() {
  group('Chant', () {
    final now = DateTime(2026, 5, 24, 12, 0, 0);

    Map<String, dynamic> validJson() => {
          'title': 'Glory Glory Man United',
          'sportId': 's1',
          'competitionId': 'c1',
          'teamId': 't1',
          'playerId': null,
          'subjectTag': 'club',
          'lyrics': 'Glory glory Man United',
          'tuneName': 'Battle Hymn of the Republic',
          'contextNotes': null,
          'coverImageUrl': null,
          'mediaUrl': null,
          'mediaType': 'none',
          'status': 'community',
          'realOrParody': 'real',
          'upvotes': 0,
          'downvotes': 0,
          'score': 0,
          'commentCount': 0,
          'createdBy': 'user1',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'flagCount': 0,
          'hidden': false,
          'removed': false,
        };

    test('fromJson and toJson round-trip', () {
      final chant = Chant.fromJson(validJson(), id: 'ch1');

      expect(chant.id, 'ch1');
      expect(chant.title, 'Glory Glory Man United');
      expect(chant.playerId, isNull);
      expect(chant.contextNotes, isNull);
      expect(chant.upvotes, 0);
      expect(chant.hidden, false);

      final output = chant.toJson();
      expect(output['title'], 'Glory Glory Man United');
      expect(output['status'], 'community');
      expect(output.containsKey('id'), false);
    });

    test('nullable playerId for player chant', () {
      final json = validJson()..['playerId'] = 'p1';
      final chant = Chant.fromJson(json, id: 'ch2');
      expect(chant.playerId, 'p1');
    });

    test('counters default to 0', () {
      final chant = Chant.fromJson(validJson(), id: 'ch3');
      expect(chant.upvotes, 0);
      expect(chant.downvotes, 0);
      expect(chant.score, 0);
      expect(chant.commentCount, 0);
      expect(chant.flagCount, 0);
    });

    test('valid subject tags', () {
      expect(Chant.validSubjectTags, contains('player'));
      expect(Chant.validSubjectTags, contains('coach'));
      expect(Chant.validSubjectTags, contains('club'));
      expect(Chant.validSubjectTags, contains('rival'));
      expect(Chant.validSubjectTags.length, 4);
    });

    test('valid media types', () {
      expect(Chant.validMediaTypes, contains('none'));
      expect(Chant.validMediaTypes, contains('audio'));
      expect(Chant.validMediaTypes, contains('crowdClip'));
      expect(Chant.validMediaTypes.length, 6);
    });

    test('valid statuses', () {
      expect(Chant.validStatuses, ['canonical', 'community']);
    });

    test('copyWith preserves unmodified fields', () {
      final chant = Chant.fromJson(validJson(), id: 'ch4');
      final updated = chant.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.lyrics, chant.lyrics);
      expect(updated.sportId, chant.sportId);
    });

    test('contextNotes is nullable (optional)', () {
      final json = validJson()..['contextNotes'] = 'Some notes';
      final chant = Chant.fromJson(json, id: 'ch5');
      expect(chant.contextNotes, 'Some notes');

      final json2 = validJson()..['contextNotes'] = null;
      final chant2 = Chant.fromJson(json2, id: 'ch6');
      expect(chant2.contextNotes, isNull);
    });
  });
}
