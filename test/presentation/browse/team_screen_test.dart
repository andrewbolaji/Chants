import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/presentation/browse/team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _ChantRepository extends Mock implements ChantRepository {
  final controller = StreamController<ChantBrowseSnapshot>.broadcast();

  @override
  Stream<ChantBrowseSnapshot> teamBrowseStream({required String teamId}) {
    return controller.stream;
  }
}

class _PlayerRepository extends Mock implements PlayerRepository {
  final controller = StreamController<List<Player>>.broadcast();

  @override
  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return controller.stream;
  }
}

const _team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

Chant _chant({
  required String id,
  required String title,
  required String status,
  int score = 0,
  String? playerId,
  DateTime? createdAt,
}) {
  final timestamp = createdAt ?? DateTime(2026, 8, 21);
  return Chant(
    id: id,
    title: title,
    sportId: _team.sportId,
    competitionId: _team.competitionId,
    teamId: _team.id,
    playerId: playerId,
    subjectTag: playerId == null ? 'club' : 'player',
    lyrics: 'Lyrics for $title',
    tuneName: 'Traditional',
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    score: score,
    createdBy: status == 'community' ? 'fan-1' : 'system',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

Widget _wrap({
  required _ChantRepository chants,
  required _PlayerRepository players,
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      chantRepositoryProvider.overrideWithValue(chants),
      playerRepositoryProvider.overrideWithValue(players),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const TeamScreen(team: _team),
    ),
  );
}

Future<void> _load(
  WidgetTester tester, {
  required _ChantRepository chants,
  required _PlayerRepository players,
  required List<Chant> data,
  bool isFromCache = false,
}) async {
  await tester.pumpWidget(_wrap(chants: chants, players: players));
  await tester.pump();
  chants.controller.add(
    ChantBrowseSnapshot(chants: data, isFromCache: isFromCache),
  );
  await tester.pump();
  players.controller.add(const [
    Player(id: 'saka', teamId: 'arsenal', name: 'Bukayo Saka'),
  ]);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('full error gives recovery guidance the screen supports', (
    tester,
  ) async {
    final chants = _ChantRepository();
    final players = _PlayerRepository();
    addTearDown(chants.controller.close);
    addTearDown(players.controller.close);

    await tester.pumpWidget(_wrap(chants: chants, players: players));
    await tester.pump();
    chants.controller.addError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load chants. Go back and try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Pull down'), findsNothing);
  });

  testWidgets('separates Songbook and Chant Lab with honest Rising copy', (
    tester,
  ) async {
    final chants = _ChantRepository();
    final players = _PlayerRepository();
    addTearDown(chants.controller.close);
    addTearDown(players.controller.close);

    await _load(
      tester,
      chants: chants,
      players: players,
      data: [
        _chant(
          id: 'proven',
          title: 'North London Forever',
          status: 'canonical',
        ),
        _chant(
          id: 'idea',
          title: 'Saka New Song',
          status: 'community',
          score: 3,
          playerId: 'saka',
        ),
      ],
    );

    expect(find.text('SONGBOOK'), findsOneWidget);
    expect(find.text('CHANT LAB'), findsOneWidget);
    expect(find.text('NORTH LONDON FOREVER'), findsOneWidget);
    expect(find.text('SAKA NEW SONG'), findsNothing);

    await tester.tap(find.text('CHANT LAB'));
    await tester.pumpAndSettle();

    expect(find.text('NORTH LONDON FOREVER'), findsNothing);
    expect(find.text('SAKA NEW SONG'), findsOneWidget);
    expect(find.text('Bukayo Saka'), findsOneWidget);
    expect(find.text('RISING'), findsOneWidget);
    expect(
      find.text(
        'Rising means early community support. It does not mean Terrace Proven.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps Top survivors stable and moves promoted status', (
    tester,
  ) async {
    final chants = _ChantRepository();
    final players = _PlayerRepository();
    addTearDown(chants.controller.close);
    addTearDown(players.controller.close);
    final a = _chant(
      id: 'a',
      title: 'First Idea',
      status: 'community',
      score: 10,
    );
    final b = _chant(
      id: 'b',
      title: 'Second Idea',
      status: 'community',
      score: 5,
    );

    await _load(tester, chants: chants, players: players, data: [a, b]);
    await tester.tap(find.text('CHANT LAB'));
    await tester.pumpAndSettle();

    chants.controller.add(
      ChantBrowseSnapshot(chants: [b.copyWith(score: 20), a]),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('FIRST IDEA')).dy,
      lessThan(tester.getTopLeft(find.text('SECOND IDEA')).dy),
    );

    chants.controller.add(
      ChantBrowseSnapshot(
        chants: [
          b.copyWith(score: 20),
          a.copyWith(status: 'canonical'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FIRST IDEA'), findsNothing);

    await tester.tap(find.text('SONGBOOK'));
    await tester.pumpAndSettle();
    expect(find.text('FIRST IDEA'), findsOneWidget);
  });

  testWidgets('cache and player failure stay inline while chants remain', (
    tester,
  ) async {
    final chants = _ChantRepository();
    final players = _PlayerRepository();
    addTearDown(chants.controller.close);
    addTearDown(players.controller.close);

    await tester.pumpWidget(_wrap(chants: chants, players: players));
    await tester.pump();
    chants.controller.add(
      ChantBrowseSnapshot(
        chants: [
          _chant(
            id: 'unknown-player',
            title: 'Mystery Player Song',
            status: 'canonical',
            playerId: 'missing',
          ),
        ],
        isFromCache: true,
      ),
    );
    await tester.pump();
    players.controller.addError(StateError('squad unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('MYSTERY PLAYER SONG'), findsOneWidget);
    expect(find.text('DEVICE CACHE'), findsOneWidget);
    expect(find.text('SQUAD UNAVAILABLE'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets(
    'tabs and controls remain usable at enlarged text on 390 by 844',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chants = _ChantRepository();
      final players = _PlayerRepository();
      addTearDown(chants.controller.close);
      addTearDown(players.controller.close);

      await tester.pumpWidget(
        _wrap(chants: chants, players: players, textScale: 1.8),
      );
      await tester.pump();
      chants.controller.add(
        ChantBrowseSnapshot(
          chants: [
            _chant(
              id: 'proven',
              title: 'A Long Terrace Proven Chant Title',
              status: 'canonical',
            ),
            _chant(
              id: 'idea',
              title: 'A Long Community Chant Idea',
              status: 'community',
              score: 4,
            ),
          ],
        ),
      );
      await tester.pump();
      players.controller.add(const [
        Player(id: 'saka', teamId: 'arsenal', name: 'Bukayo Saka'),
      ]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('CHANT LAB'));
      await tester.pumpAndSettle();
      expect(find.text('TOP'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
