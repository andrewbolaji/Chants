import 'dart:convert';
import 'dart:io';

import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/repositories/songbook_storage.dart';
import 'package:chants/data/services/sha256.dart';
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
  test('SHA-256 covers the empty-message padding path directly', () {
    expect(
      sha256Hex(const []),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test('UID storage keys are lowercase SHA-256 and case-collision safe', () {
    expect(() => songbookStorageKeyForUid(''), throwsArgumentError);
    expect(
      songbookStorageKeyForUid('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    final first = songbookStorageKeyForUid('AAGxxxxxxxxxxxxxxxxxxxxxxxxx');
    final second = songbookStorageKeyForUid('AAaxxxxxxxxxxxxxxxxxxxxxxxxx');
    expect(first, isNot(equalsIgnoringCase(second)));
    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('SHA-256 storage keys cover multi-block and padding boundaries', () {
    expect(
      songbookStorageKeyForUid(
        'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
      ),
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    );
    expect(
      songbookStorageKeyForUid('a' * 55),
      '9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318',
    );
    expect(
      songbookStorageKeyForUid('a' * 56),
      'b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a',
    );
    expect(
      songbookStorageKeyForUid('a' * 64),
      'ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb',
    );
  });

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

  test('active UID lazily migrates its legacy base64 filename', () async {
    final directory = await Directory.systemTemp.createTemp(
      'chants-songbook-migration-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final songbookDirectory = Directory('${directory.path}/matchday_songbook');
    await songbookDirectory.create(recursive: true);
    const uid = 'fan-a';
    final legacyKey = base64Url.encode(utf8.encode(uid)).replaceAll('=', '');
    final legacyFile = File('${songbookDirectory.path}/$legacyKey.json');
    await legacyFile.writeAsString('{"schemaVersion":1}');

    final storage = FileSongbookStorage(
      supportDirectory: () async => directory,
    );
    expect(await storage.read(uid), '{"schemaVersion":1}');

    final hashedFile = File(
      '${songbookDirectory.path}/${songbookStorageKeyForUid(uid)}.json',
    );
    expect(await hashedFile.exists(), isTrue);
    expect(await legacyFile.exists(), isFalse);
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

  test(
    'prepared deletion artifact restores after repository reconstruction',
    () async {
      final encoded = jsonEncode(SavedSongbook.empty().toJson());
      final storage = MemorySongbookStorage()..active['fan-a'] = encoded;
      await storage.stageForAccountDeletion('fan-a');
      expect(storage.preparedTombstones['fan-a'], encoded);

      final reconstructed = SavedSongbookRepository(storage: storage);
      await reconstructed.load('fan-a');

      expect(storage.active['fan-a'], encoded);
      expect(storage.preparedTombstones, isEmpty);
    },
  );

  test(
    'prepared deletion artifact can recover without reconstruction',
    () async {
      final encoded = jsonEncode(SavedSongbook.empty().toJson());
      final storage = MemorySongbookStorage()..active['fan-a'] = encoded;
      final repository = SavedSongbookRepository(storage: storage);
      await repository.load('fan-a');
      await storage.stageForAccountDeletion('fan-a');

      expect(
        await repository.accountDeletionState('fan-a'),
        SongbookAccountDeletionState.prepared,
      );
      expect(
        await repository.retryAccountDeletionArtifactRecovery('fan-a'),
        SongbookAccountDeletionState.none,
      );
      expect(storage.active['fan-a'], encoded);
      expect(storage.preparedTombstones, isEmpty);
    },
  );

  test(
    'unknown deletion artifact is preserved and remains unreadable',
    () async {
      final storage = MemorySongbookStorage()..active['fan-a'] = '{}';
      await storage.stageForAccountDeletion('fan-a');
      await storage.markAccountDeletionRequestStarted('fan-a');

      final reconstructed = SavedSongbookRepository(storage: storage);
      expect((await reconstructed.load('fan-a')).uniqueChantIds, isEmpty);
      expect(
        await reconstructed.accountDeletionState('fan-a'),
        SongbookAccountDeletionState.unknown,
      );
      expect(storage.active, isEmpty);
      expect(storage.unknownTombstones['fan-a'], '{}');
    },
  );

  test('unknown file state outranks a conflicting active artifact', () async {
    final directory = await Directory.systemTemp.createTemp(
      'chants-songbook-unknown-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = FileSongbookStorage(
      supportDirectory: () async => directory,
    );
    const uid = 'fan-a';
    await storage.writeAtomically(uid, '{"original":true}');
    await storage.stageForAccountDeletion(uid);
    await storage.markAccountDeletionRequestStarted(uid);

    final songbookDirectory = Directory('${directory.path}/matchday_songbook');
    final active = File(
      '${songbookDirectory.path}/${songbookStorageKeyForUid(uid)}.json',
    );
    await active.writeAsString('{"conflict":true}');

    expect(await storage.read(uid), isNull);
    await expectLater(
      storage.writeAtomically(uid, '{"replacement":true}'),
      throwsStateError,
    );

    await storage.markAccountDeletionAccepted(uid);
    await storage.finishAccountDeletion(uid);

    expect(await active.exists(), isFalse);
    expect(
      await storage.accountDeletionState(uid),
      SongbookAccountDeletionState.none,
    );
  });

  test('accepted deletion artifact is removed after reconstruction', () async {
    final storage = MemorySongbookStorage()..active['fan-a'] = '{}';
    await storage.stageForAccountDeletion('fan-a');
    await storage.markAccountDeletionRequestStarted('fan-a');
    await storage.markAccountDeletionAccepted('fan-a');
    expect(storage.acceptedTombstones['fan-a'], '{}');

    final reconstructed = SavedSongbookRepository(storage: storage);
    expect((await reconstructed.load('fan-a')).uniqueChantIds, isEmpty);
    expect(storage.acceptedTombstones, isEmpty);
  });

  test(
    'confirmed deletion removes conflicting artifacts accepted-marker last',
    () async {
      final storage = MemorySongbookStorage()
        ..active['fan-a'] = '{"conflict":true}'
        ..unknownTombstones['fan-a'] = '{"original":true}';
      final repository = SavedSongbookRepository(storage: storage);

      await repository.confirmAccountDeletionAccepted('fan-a');

      expect(storage.active, isEmpty);
      expect(storage.preparedTombstones, isEmpty);
      expect(storage.unknownTombstones, isEmpty);
      expect(storage.acceptedTombstones, isEmpty);
      expect(
        await repository.accountDeletionState('fan-a'),
        SongbookAccountDeletionState.none,
      );
    },
  );

  test('a transient initialization failure can be retried', () async {
    final storage = MemorySongbookStorage()..failRecoveryOnce = true;
    final repository = SavedSongbookRepository(storage: storage);

    await expectLater(repository.load('fan-a'), throwsStateError);
    expect((await repository.load('fan-a')).uniqueChantIds, isEmpty);
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
