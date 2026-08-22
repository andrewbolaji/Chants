import 'dart:convert';

import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:flutter_test/flutter_test.dart';

const team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

Chant chant(String id, {String status = 'canonical'}) {
  return Chant(
    id: id,
    title: 'Song $id',
    sportId: team.sportId,
    competitionId: team.competitionId,
    teamId: team.id,
    subjectTag: 'club',
    lyrics: 'Lyrics for $id',
    tuneName: 'Traditional',
    contextNotes: 'North Bank',
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    createdBy: 'system',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
    variations: const [ChantVariation(label: 'Away', lyric: 'Away lyrics')],
  );
}

SavedSongbook fixture() {
  final timestamp = DateTime.utc(2026, 8, 22, 19);
  return SavedSongbook(
    clubSnapshots: {
      team.id: SavedClubSongbook(
        team: SavedTeamIdentity.fromTeam(team),
        savedAt: timestamp,
        refreshedAt: timestamp,
        chants: [SavedChantSnapshot.fromChant(chant('one'))],
      ),
    },
    individualSnapshots: {
      'idea': SavedIndividualChant(
        team: SavedTeamIdentity.fromTeam(team),
        savedAt: timestamp,
        refreshedAt: timestamp,
        chant: SavedChantSnapshot.fromChant(chant('idea', status: 'community')),
      ),
    },
  );
}

void main() {
  test('round trips only bounded offline display data', () {
    final encoded = jsonEncode(fixture().toJson());
    final decoded = SavedSongbook.fromJson(jsonDecode(encoded));

    expect(decoded.clubSnapshots.keys, [team.id]);
    expect(decoded.individualSnapshots.keys, ['idea']);
    final saved = decoded.clubSnapshots[team.id]!.chants.single;
    expect(saved.lyrics, 'Lyrics for one');
    expect(saved.variations.single.label, 'Away');
    expect(saved.createdAt.isUtc, isTrue);
    expect(encoded, isNot(contains('createdBy')));
    expect(encoded, isNot(contains('upvotes')));
    expect(encoded, isNot(contains('evidence')));
    expect(encoded, isNot(contains('mediaUrl')));
  });

  test('ignores additive fields in schema version 1', () {
    final json = fixture().toJson()..['futureOptionalField'] = true;
    final decoded = SavedSongbook.fromJson(json);
    expect(decoded.uniqueChantIds, {'one', 'idea'});
  });

  test('rejects a future version without treating it as empty', () {
    final json = fixture().toJson()..['schemaVersion'] = 2;
    expect(
      () => SavedSongbook.fromJson(json),
      throwsA(isA<UnsupportedSavedSongbookVersion>()),
    );
  });

  test('rejects mismatched keys, invalid status, and non-UTC dates', () {
    final mismatched = fixture().toJson();
    mismatched['clubSnapshots'] = {
      'chelsea': (mismatched['clubSnapshots'] as Map)[team.id],
    };
    expect(
      () => SavedSongbook.fromJson(mismatched),
      throwsA(isA<SavedSongbookFormatException>()),
    );

    final invalidStatus = fixture().toJson();
    final club = (invalidStatus['clubSnapshots'] as Map)[team.id] as Map;
    (club['chants'] as List).single['status'] = 'mystery';
    expect(
      () => SavedSongbook.fromJson(invalidStatus),
      throwsA(isA<SavedSongbookFormatException>()),
    );

    final localDate = fixture().toJson();
    final localClub = (localDate['clubSnapshots'] as Map)[team.id] as Map;
    localClub['savedAt'] = '2026-08-22T19:00:00';
    expect(
      () => SavedSongbook.fromJson(localDate),
      throwsA(isA<SavedSongbookFormatException>()),
    );
  });

  test('rejects duplicate chant IDs inside one club snapshot', () {
    final json = fixture().toJson();
    final club = (json['clubSnapshots'] as Map)[team.id] as Map;
    club['chants'] = [...(club['chants'] as List), ...(club['chants'] as List)];
    expect(
      () => SavedSongbook.fromJson(json),
      throwsA(isA<SavedSongbookFormatException>()),
    );
  });

  test('rejects more than 500 unique chant IDs', () {
    final timestamp = DateTime.utc(2026, 8, 22);
    expect(
      () => SavedSongbook(
        individualSnapshots: {
          for (var index = 0; index <= SavedSongbook.maxUniqueChants; index++)
            'chant-$index': SavedIndividualChant(
              team: SavedTeamIdentity.fromTeam(team),
              savedAt: timestamp,
              refreshedAt: timestamp,
              chant: SavedChantSnapshot.fromChant(chant('chant-$index')),
            ),
        },
      ),
      throwsA(isA<SavedSongbookLimitException>()),
    );
  });

  test('500-chant codec workload remains measurable and deterministic', () {
    final timestamp = DateTime.utc(2026, 8, 22);
    final fixture = SavedSongbook(
      individualSnapshots: {
        for (var index = 0; index < SavedSongbook.maxUniqueChants; index++)
          'chant-$index': SavedIndividualChant(
            team: SavedTeamIdentity.fromTeam(team),
            savedAt: timestamp,
            refreshedAt: timestamp,
            chant: SavedChantSnapshot.fromChant(chant('chant-$index')),
          ),
      },
    );
    final watch = Stopwatch()..start();
    final decoded = SavedSongbook.fromJson(
      jsonDecode(jsonEncode(fixture.toJson())),
    );
    watch.stop();

    expect(decoded.uniqueChantIds.length, SavedSongbook.maxUniqueChants);
    expect(
      decoded.individualSnapshots['chant-499']!.chant.lyrics,
      'Lyrics for chant-499',
    );
    // Diagnostic only. CI timing is intentionally not a correctness gate.
    // ignore: avoid_print
    print('500-chant Saved Songbook codec: ${watch.elapsedMicroseconds} us');
  });
}
