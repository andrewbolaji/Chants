import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_browse.dart';
import 'package:flutter_test/flutter_test.dart';

Chant _chant({
  required String id,
  String status = 'community',
  int score = 0,
  DateTime? createdAt,
}) {
  final timestamp = createdAt ?? DateTime.utc(2026, 8, 20);
  return Chant(
    id: id,
    title: 'Title $id',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'club',
    lyrics: 'Lyrics $id',
    tuneName: 'Tune $id',
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    score: score,
    createdBy: 'user-1',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  group('projectChants', () {
    test('partitions canonical and community status only', () {
      final projection = projectChants([
        _chant(id: 'community'),
        _chant(id: 'canonical', status: 'canonical'),
        _chant(id: 'future', status: 'editorial'),
      ]);

      expect(projection.songbook.map((chant) => chant.id), ['canonical']);
      expect(projection.chantLab.map((chant) => chant.id), ['community']);
      expect(projection.unsupportedStatuses, {'editorial'});
    });

    test('does not mutate the input', () {
      final chants = [
        _chant(id: 'community'),
        _chant(id: 'canonical', status: 'canonical'),
      ];

      projectChants(chants);

      expect(chants.map((chant) => chant.id), ['community', 'canonical']);
    });
  });

  group('browse ranking', () {
    test('Top uses score, oldest creation, then ID and keeps negatives', () {
      final ranked = rankBrowseTop([
        _chant(id: 'negative', score: -2),
        _chant(id: 'newer', score: 4, createdAt: DateTime.utc(2026, 8, 21)),
        _chant(id: 'b', score: 4, createdAt: DateTime.utc(2026, 8, 20)),
        _chant(id: 'a', score: 4, createdAt: DateTime.utc(2026, 8, 20)),
      ]);

      expect(ranked.map((chant) => chant.id), ['a', 'b', 'newer', 'negative']);
    });

    test('New uses newest creation then ID', () {
      final ranked = rankBrowseNew([
        _chant(id: 'older', createdAt: DateTime.utc(2026, 8, 19)),
        _chant(id: 'b', createdAt: DateTime.utc(2026, 8, 21)),
        _chant(id: 'a', createdAt: DateTime.utc(2026, 8, 21)),
      ]);

      expect(ranked.map((chant) => chant.id), ['a', 'b', 'older']);
    });
  });

  group('isRisingChant', () {
    final now = DateTime.utc(2026, 8, 22, 12);

    test('includes the exact seven-day and score-three boundary', () {
      final chant = _chant(
        id: 'boundary',
        score: 3,
        createdAt: now.subtract(const Duration(days: 7)),
      );

      expect(isRisingChant(chant, now: now), isTrue);
    });

    test('rejects canonical, future, old, and low-score chants', () {
      expect(
        isRisingChant(
          _chant(id: 'canonical', status: 'canonical', score: 20),
          now: now,
        ),
        isFalse,
      );
      expect(
        isRisingChant(
          _chant(
            id: 'future',
            score: 20,
            createdAt: now.add(const Duration(seconds: 1)),
          ),
          now: now,
        ),
        isFalse,
      );
      expect(
        isRisingChant(
          _chant(
            id: 'old',
            score: 20,
            createdAt: now.subtract(const Duration(days: 7, seconds: 1)),
          ),
          now: now,
        ),
        isFalse,
      );
      expect(isRisingChant(_chant(id: 'low', score: 2), now: now), isFalse);
    });
  });

  group('StableChantOrder', () {
    test(
      'keeps survivors stable, removes missing IDs, and appends newcomers',
      () {
        final order = StableChantOrder();
        final a = _chant(id: 'a', score: 5);
        final b = _chant(id: 'b', score: 3);

        expect(order.reconcile([a, b]).map((chant) => chant.id), ['a', 'b']);

        final rescoredB = b.copyWith(score: 10);
        final newcomer = _chant(id: 'new', score: 20);
        expect(
          order.reconcile([newcomer, rescoredB, a]).map((chant) => chant.id),
          ['a', 'b', 'new'],
        );

        expect(
          order.reconcile([newcomer, rescoredB]).map((chant) => chant.id),
          ['b', 'new'],
        );
      },
    );

    test('reset adopts the next deterministic order as a fresh visit', () {
      final order = StableChantOrder();
      final a = _chant(id: 'a', score: 1);
      final b = _chant(id: 'b', score: 2);
      order.reconcile([a, b]);

      order.reset();

      expect(order.reconcile([b, a]).map((chant) => chant.id), ['b', 'a']);
    });
  });
}
