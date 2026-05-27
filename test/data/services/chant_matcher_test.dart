import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_matcher.dart';

Chant _makeChant({
  required String title,
  String tuneName = 'Original',
  String id = 'test',
}) {
  return Chant(
    id: id,
    title: title,
    sportId: 's1',
    competitionId: 'c1',
    teamId: 't1',
    subjectTag: 'club',
    lyrics: 'test lyrics',
    tuneName: tuneName,
    mediaType: 'none',
    status: 'community',
    realOrParody: 'real',
    createdBy: 'user1',
    createdAt: DateTime(2026, 5, 27),
    updatedAt: DateTime(2026, 5, 27),
  );
}

void main() {
  final matcher = ChantMatcher();

  group('ChantMatcher', () {
    test('exact title match scores 1.0', () {
      final candidates = [_makeChant(title: 'One Nil to the Arsenal')];
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results.length, 1);
      expect(results.first.score, 1.0);
    });

    test('partial overlap scores proportionally', () {
      // 3 of 5 unique tokens shared: one, nil, arsenal
      // submission: {one, nil, to, the, arsenal} (5)
      // candidate: {one, nil, arsenal, forever} (4)
      // intersection: {one, nil, arsenal} = 3
      // union: {one, nil, to, the, arsenal, forever} = 6
      // score: 3/6 = 0.5
      final candidates = [_makeChant(title: 'One Nil Arsenal Forever')];
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results.length, 1);
      expect(results.first.score, 0.5);
    });

    test('no overlap scores 0.0 and is excluded', () {
      final candidates = [_makeChant(title: 'Blue Moon Rising')];
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results, isEmpty);
    });

    test('tune boost adds 0.2 when tune matches', () {
      // Title overlap: 3/6 = 0.5, tune matches, boosted to 0.7
      final candidates = [
        _makeChant(title: 'One Nil Arsenal Forever', tuneName: 'Go West'),
      ];
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: 'Go West',
        candidates: candidates,
      );
      expect(results.length, 1);
      expect(results.first.score, closeTo(0.7, 0.01));
    });

    test('tune boost does not exceed 1.0', () {
      final candidates = [
        _makeChant(title: 'One Nil to the Arsenal', tuneName: 'Go West'),
      ];
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: 'Go West',
        candidates: candidates,
      );
      expect(results.first.score, 1.0);
    });

    test('below-threshold results excluded', () {
      // 1 shared token out of many: score < 0.4
      final candidates = [_makeChant(title: 'The Mighty Blues March On')];
      final results = matcher.findMatches(
        title: 'The Arsenal Song',
        tuneName: '',
        candidates: candidates,
      );
      // 'the' is the only shared token: 1/6 = 0.17
      expect(results, isEmpty);
    });

    test('results sorted descending by score', () {
      final candidates = [
        _makeChant(title: 'Arsenal Song', id: 'low'),
        _makeChant(title: 'One Nil to the Arsenal', id: 'high'),
      ];
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results.first.chant.id, 'high');
    });

    test('max 3 results returned', () {
      final candidates = List.generate(
        10,
        (i) => _makeChant(title: 'One Nil to the Arsenal $i', id: 'c$i'),
      );
      final results = matcher.findMatches(
        title: 'One Nil to the Arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results.length, lessThanOrEqualTo(MatcherConfig.maxResults));
    });

    test('normalization: punctuation stripped, case ignored', () {
      final candidates = [
        _makeChant(title: "ONE NIL TO THE ARSENAL!"),
      ];
      final results = matcher.findMatches(
        title: 'one nil to the arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results.length, 1);
      expect(results.first.score, 1.0);
    });

    test('empty title returns no matches', () {
      final candidates = [_makeChant(title: 'Something')];
      final results = matcher.findMatches(
        title: '',
        tuneName: '',
        candidates: candidates,
      );
      expect(results, isEmpty);
    });

    test('empty candidates returns no matches', () {
      final results = matcher.findMatches(
        title: 'One Nil',
        tuneName: '',
        candidates: [],
      );
      expect(results, isEmpty);
    });

    // Adversarial case 1: false positive at threshold 0.4
    // "The Saka Song" vs "The Rice Song" share "the" and "song" (2/4 = 0.5)
    // This is a documented acceptable false-positive nudge.
    test('adversarial: "The Saka Song" vs "The Rice Song" scores ~0.5 (false positive, accepted)', () {
      final candidates = [_makeChant(title: 'The Rice Song')];
      final results = matcher.findMatches(
        title: 'The Saka Song',
        tuneName: '',
        candidates: candidates,
      );
      expect(results.length, 1);
      expect(results.first.score, closeTo(0.5, 0.01));
    });

    // Adversarial case 2: no match below threshold
    // "Up the Arsenal" vs "Pride of Arsenal": tokens {up, the, arsenal} vs {pride, of, arsenal}
    // intersection: {arsenal} = 1, union: {up, the, arsenal, pride, of} = 5
    // score: 1/5 = 0.2, below threshold
    test('adversarial: "Up the Arsenal" vs "Pride of Arsenal" scores 0.2 (no nudge)', () {
      final candidates = [_makeChant(title: 'Pride of Arsenal')];
      final results = matcher.findMatches(
        title: 'Up the Arsenal',
        tuneName: '',
        candidates: candidates,
      );
      expect(results, isEmpty);
    });
  });
}
