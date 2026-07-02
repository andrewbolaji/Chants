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
          'chantType': 'sincere',
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

    test('variations defaults to empty list when key absent', () {
      // validJson() has no 'variations' key
      final chant = Chant.fromJson(validJson(), id: 'ch7');
      expect(chant.variations, isEmpty);
      expect(chant.variations, isA<List<ChantVariation>>());
    });

    test('variations defaults to empty list when key is null', () {
      final json = validJson()..['variations'] = null;
      final chant = Chant.fromJson(json, id: 'ch8');
      expect(chant.variations, isEmpty);
    });

    test('variations round-trips with entries', () {
      final json = validJson()
        ..['variations'] = [
          {'label': 'Alt', 'lyric': 'Alt lyric', 'contextNote': 'A note'},
          {'label': 'Original', 'lyric': 'Old lyric', 'contextNote': null},
        ];
      final chant = Chant.fromJson(json, id: 'ch9');
      expect(chant.variations.length, 2);
      expect(chant.variations[0].label, 'Alt');
      expect(chant.variations[0].lyric, 'Alt lyric');
      expect(chant.variations[0].contextNote, 'A note');
      expect(chant.variations[1].contextNote, isNull);

      final output = chant.toJson();
      final outVars = output['variations'] as List;
      expect(outVars.length, 2);
      expect((outVars[0] as Map)['label'], 'Alt');
    });

    test('copyWith preserves variations when not overridden', () {
      final json = validJson()
        ..['variations'] = [
          {'label': 'V1', 'lyric': 'Lyric 1'},
        ];
      final chant = Chant.fromJson(json, id: 'ch10');
      final updated = chant.copyWith(title: 'New');
      expect(updated.variations.length, 1);
      expect(updated.variations[0].label, 'V1');
    });
  });
}
