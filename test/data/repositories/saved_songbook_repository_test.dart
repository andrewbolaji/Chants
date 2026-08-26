import 'dart:io';

import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/repositories/songbook_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/memory_songbook_storage.dart';

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
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    createdBy: 'system',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

void main() {
  test('file snapshot survives repository reconstruction', () async {
    final directory = await Directory.systemTemp.createTemp(
      'chants-songbook-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = FileSongbookStorage(
      supportDirectory: () async => directory,
    );
    final first = SavedSongbookRepository(storage: storage);
    await first.saveClub(
      uid: 'fan-a',
      team: team,
      chants: [chant('one')],
      refreshedAt: DateTime.utc(2026, 8, 22, 19),
    );

    final reconstructed = SavedSongbookRepository(
      storage: FileSongbookStorage(supportDirectory: () async => directory),
    );
    final loaded = await reconstructed.load('fan-a');
    expect(
      loaded.clubSnapshots[team.id]!.chants.single.lyrics,
      'Lyrics for one',
    );
    expect((await reconstructed.load('fan-b')).uniqueChantIds, isEmpty);
  });

  test('different UIDs cannot read each other snapshots', () async {
    final storage = MemorySongbookStorage();
    final repository = SavedSongbookRepository(storage: storage);
    await repository.saveIndividual(
      uid: 'fan-a',
      team: team,
      chant: chant('private-choice', status: 'community'),
      refreshedAt: DateTime.utc(2026, 8, 22),
    );

    expect((await repository.load('fan-a')).individualSnapshots, isNotEmpty);
    expect((await repository.load('fan-b')).individualSnapshots, isEmpty);
  });

  test('access guard rejects a stale UID after account switching', () async {
    final storage = MemorySongbookStorage();
    var currentUid = 'fan-a';
    final repository = SavedSongbookRepository(
      storage: storage,
      canAccess: (uid) => uid == currentUid,
    );
    await repository.saveIndividual(
      uid: 'fan-a',
      team: team,
      chant: chant('one'),
      refreshedAt: DateTime.utc(2026, 8, 22),
    );

    currentUid = 'fan-b';
    await expectLater(
      repository.load('fan-a'),
      throwsA(isA<SavedSongbookAccessException>()),
    );
    await expectLater(
      repository.removeIndividual(uid: 'fan-a', chantId: 'one'),
      throwsA(isA<SavedSongbookAccessException>()),
    );
    expect(storage.active['fan-a'], isNotNull);
    expect((await repository.load('fan-b')).uniqueChantIds, isEmpty);
  });

  test('failed atomic write preserves the prior file', () async {
    final storage = MemorySongbookStorage();
    final repository = SavedSongbookRepository(storage: storage);
    await repository.saveIndividual(
      uid: 'fan-a',
      team: team,
      chant: chant('one'),
      refreshedAt: DateTime.utc(2026, 8, 22),
    );
    final priorBytes = storage.active['fan-a'];
    storage.failWrite = true;

    await expectLater(
      repository.saveIndividual(
        uid: 'fan-a',
        team: team,
        chant: chant('two'),
        refreshedAt: DateTime.utc(2026, 8, 23),
      ),
      throwsStateError,
    );
    expect(storage.active['fan-a'], priorBytes);
  });

  test('overlapping mutations serialize without losing an update', () async {
    final storage = DeferredFirstWriteSongbookStorage();
    final repository = SavedSongbookRepository(storage: storage);
    final first = repository.saveIndividual(
      uid: 'fan-a',
      team: team,
      chant: chant('one'),
      refreshedAt: DateTime.utc(2026, 8, 22),
    );
    await storage.firstWriteStarted.future;
    final second = repository.saveIndividual(
      uid: 'fan-a',
      team: team,
      chant: chant('two'),
      refreshedAt: DateTime.utc(2026, 8, 23),
    );
    storage.releaseFirstWrite.complete();
    await Future.wait([first, second]);

    expect(
      (await repository.load('fan-a')).individualSnapshots.keys,
      containsAll(['one', 'two']),
    );
  });

  test('write rejects a payload beyond the 2 MiB boundary', () async {
    final storage = MemorySongbookStorage();
    final repository = SavedSongbookRepository(storage: storage);
    final oversized = chant('large').copyWith(
      lyrics: List.filled(SavedSongbook.maxEncodedBytes + 1, 'x').join(),
    );

    await expectLater(
      repository.saveIndividual(
        uid: 'fan-a',
        team: team,
        chant: oversized,
        refreshedAt: DateTime.utc(2026, 8, 22),
      ),
      throwsA(isA<SavedSongbookLimitException>()),
    );
    expect(storage.active, isEmpty);
  });
}
