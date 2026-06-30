import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_ranking.dart';

/// Helper to build a minimal Chant with the fields that matter for ranking.
Chant _chant({
  required String id,
  int score = 0,
  String status = 'community',
  DateTime? createdAt,
}) {
  final ts = createdAt ?? DateTime(2025, 1, 1);
  return Chant(
    id: id,
    title: 'Title $id',
    sportId: 'football',
    competitionId: 'pl',
    teamId: 'team-a',
    subjectTag: 'club',
    lyrics: 'la la la',
    tuneName: 'original',
    mediaType: 'none',
    status: status,
    realOrParody: 'real',
    score: score,
    createdBy: 'seed',
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('rankChants', () {
    test('sorts by the full four-key rule with varied scores including negative',
        () {
      final chants = [
        _chant(id: 'c', score: 0, status: 'community', createdAt: DateTime(2025, 3, 1)),
        _chant(id: 'a', score: 5, status: 'canonical', createdAt: DateTime(2025, 1, 1)),
        _chant(id: 'e', score: -2, status: 'community', createdAt: DateTime(2025, 5, 1)),
        _chant(id: 'b', score: 5, status: 'community', createdAt: DateTime(2025, 2, 1)),
        _chant(id: 'd', score: 0, status: 'canonical', createdAt: DateTime(2025, 4, 1)),
      ];

      final ranked = rankChants(chants);
      final ids = ranked.map((c) => c.id).toList();

      // score 5: canonical 'a' before community 'b'
      // score 0: canonical 'd' before community 'c'
      // score -2: 'e' last
      expect(ids, ['a', 'b', 'd', 'c', 'e']);
    });

    test('determinism: same input gives identical order on repeated calls', () {
      final chants = [
        _chant(id: 'z', score: 3),
        _chant(id: 'y', score: 1),
        _chant(id: 'x', score: 3),
      ];

      final first = rankChants(chants).map((c) => c.id).toList();
      final second = rankChants(chants).map((c) => c.id).toList();

      expect(first, second);
    });

    test('canonical before community on equal score', () {
      final chants = [
        _chant(id: 'b', score: 7, status: 'community', createdAt: DateTime(2025, 1, 1)),
        _chant(id: 'a', score: 7, status: 'canonical', createdAt: DateTime(2025, 1, 1)),
      ];

      final ranked = rankChants(chants);
      expect(ranked.first.id, 'a');
      expect(ranked.last.id, 'b');
    });

    test('equal score and status: createdAt ascending (oldest first)', () {
      final chants = [
        _chant(id: 'b', score: 4, status: 'community', createdAt: DateTime(2025, 6, 1)),
        _chant(id: 'a', score: 4, status: 'community', createdAt: DateTime(2025, 1, 1)),
      ];

      final ranked = rankChants(chants);
      expect(ranked.first.id, 'a');
      expect(ranked.last.id, 'b');
    });

    test('equal score, status, and createdAt: id ascending as tie-break', () {
      final ts = DateTime(2025, 3, 15);
      final chants = [
        _chant(id: 'beta', score: 2, status: 'community', createdAt: ts),
        _chant(id: 'alpha', score: 2, status: 'community', createdAt: ts),
      ];

      final ranked = rankChants(chants);
      expect(ranked.first.id, 'alpha');
      expect(ranked.last.id, 'beta');
    });

    test('negative scores sort below zero and positive, and are NOT dropped', () {
      final chants = [
        _chant(id: 'neg', score: -5),
        _chant(id: 'zero', score: 0),
        _chant(id: 'pos', score: 3),
      ];

      final ranked = rankChants(chants);
      final ids = ranked.map((c) => c.id).toList();

      expect(ids, ['pos', 'zero', 'neg']);
      expect(ranked.length, 3, reason: 'negative score chant must not be dropped');
    });

    test('does not mutate the input list', () {
      final chants = [
        _chant(id: 'b', score: 1),
        _chant(id: 'a', score: 2),
      ];
      final originalFirst = chants.first.id;

      rankChants(chants);

      expect(chants.first.id, originalFirst);
    });

    test('empty input returns empty list', () {
      expect(rankChants([]), isEmpty);
    });

    test('single chant returns a list with that chant', () {
      final chants = [_chant(id: 'only', score: 42)];
      final ranked = rankChants(chants);
      expect(ranked.length, 1);
      expect(ranked.first.id, 'only');
    });
  });
}
