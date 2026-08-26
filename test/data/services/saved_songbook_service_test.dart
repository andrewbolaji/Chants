import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/data/services/saved_songbook_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_songbook_storage.dart';

const team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

Chant chant(String id, {String status = 'canonical', int score = 0}) {
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
    score: score,
    createdBy: 'system',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

class FakeChantRepository extends Mock implements ChantRepository {
  List<Chant> visible = [];
  Object? error;

  @override
  Future<List<Chant>> visibleChantsForTeamFromServer({
    required String teamId,
  }) async {
    if (error != null) throw error!;
    return List.unmodifiable(visible);
  }
}

class FakeTeamRepository extends Mock implements TeamRepository {
  Team? value = team;
  Object? error;

  @override
  Future<Team?> getTeamFromServer(String id) async {
    if (error != null) throw error!;
    return value;
  }
}

void main() {
  late MemorySongbookStorage storage;
  late SavedSongbookRepository savedRepository;
  late FakeChantRepository chantRepository;
  late FakeTeamRepository teamRepository;
  late SavedSongbookService service;

  setUp(() {
    storage = MemorySongbookStorage();
    savedRepository = SavedSongbookRepository(storage: storage);
    chantRepository = FakeChantRepository();
    teamRepository = FakeTeamRepository();
    service = SavedSongbookService(
      savedRepository: savedRepository,
      chantRepository: chantRepository,
      teamRepository: teamRepository,
      now: () => DateTime.utc(2026, 8, 22, 19),
    );
  });

  test(
    'overview renders a club-owned chant once and reveals individual intent',
    () async {
      await savedRepository.saveClub(
        uid: 'fan',
        team: team,
        chants: [chant('same')],
        refreshedAt: DateTime.utc(2026, 8, 22),
      );
      await savedRepository.saveIndividual(
        uid: 'fan',
        team: team,
        chant: chant('same'),
        refreshedAt: DateTime.utc(2026, 8, 22),
      );
      await savedRepository.saveIndividual(
        uid: 'fan',
        team: team,
        chant: chant('other', status: 'community'),
        refreshedAt: DateTime.utc(2026, 8, 23),
      );

      final before = projectSavedSongbook(await savedRepository.load('fan'));
      expect(before.clubs.single.chants.map((item) => item.id), ['same']);
      expect(before.individualChants.map((item) => item.chant.id), ['other']);

      await savedRepository.removeClub(uid: 'fan', teamId: team.id);
      final after = projectSavedSongbook(await savedRepository.load('fan'));
      expect(
        after.individualChants.map((item) => item.chant.id),
        containsAll(['same', 'other']),
      );
    },
  );

  test('club refresh atomically drops demoted and missing chants', () async {
    await savedRepository.saveClub(
      uid: 'fan',
      team: team,
      chants: [chant('keep'), chant('demoted'), chant('hidden')],
      refreshedAt: DateTime.utc(2026, 8, 21),
    );
    chantRepository.visible = [
      chant('keep', score: 4),
      chant('demoted', status: 'community', score: 20),
    ];

    final result = await service.refreshClub(uid: 'fan', teamId: team.id);
    expect(result.chantCount, 1);
    expect(
      result.songbook.clubSnapshots[team.id]!.chants.map((item) => item.id),
      ['keep'],
    );
  });

  test('failed club refresh retains exact prior local bytes', () async {
    await savedRepository.saveClub(
      uid: 'fan',
      team: team,
      chants: [chant('keep')],
      refreshedAt: DateTime.utc(2026, 8, 21),
    );
    final prior = storage.active['fan'];
    chantRepository.error = StateError('offline');

    await expectLater(
      service.refreshClub(uid: 'fan', teamId: team.id),
      throwsStateError,
    );
    expect(storage.active['fan'], prior);
  });

  test(
    'target refresh reconciles canonical, community, and missing states',
    () async {
      await savedRepository.saveClub(
        uid: 'fan',
        team: team,
        chants: [chant('target')],
        refreshedAt: DateTime.utc(2026, 8, 21),
      );
      await savedRepository.saveIndividual(
        uid: 'fan',
        team: team,
        chant: chant('target'),
        refreshedAt: DateTime.utc(2026, 8, 21),
      );

      chantRepository.visible = [
        chant('target', status: 'community', score: 10),
      ];
      final demoted = await service.refreshIndividual(
        uid: 'fan',
        chantId: 'target',
      );
      expect(demoted.songbook.clubSnapshots[team.id]!.chants, isEmpty);
      expect(
        demoted.songbook.individualSnapshots['target']!.chant.status,
        'community',
      );

      chantRepository.visible = [];
      final removed = await service.refreshIndividual(
        uid: 'fan',
        chantId: 'target',
      );
      expect(removed.removed, isTrue);
      expect(removed.songbook.individualSnapshots, isEmpty);
    },
  );

  test(
    'first individual save requires a server-visible target and team',
    () async {
      chantRepository.visible = [];
      await expectLater(
        service.saveIndividual(uid: 'fan', chantId: 'missing', teamId: team.id),
        throwsA(isA<SavedChantNotVisibleException>()),
      );

      chantRepository.visible = [chant('found')];
      teamRepository.value = null;
      await expectLater(
        service.saveIndividual(uid: 'fan', chantId: 'found', teamId: team.id),
        throwsA(isA<SavedTeamUnavailableException>()),
      );
    },
  );
}
