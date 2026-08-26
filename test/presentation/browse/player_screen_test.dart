import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/vote.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/presentation/browse/player_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'fan-1';
}

class _ChantRepository extends Mock implements ChantRepository {
  final controller = StreamController<ChantBrowseSnapshot>.broadcast();

  @override
  Stream<ChantBrowseSnapshot> playerBrowseStream({required String playerId}) {
    return controller.stream;
  }
}

class _VoteRepository extends Mock implements VoteRepository {
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async => null;
}

const _player = Player(id: 'saka', teamId: 'arsenal', name: 'Bukayo Saka');

Chant _chant({required String id, required String status}) {
  final timestamp = DateTime(2026, 8, 21);
  return Chant(
    id: id,
    title: status == 'canonical' ? 'Saka Proven' : 'Saka Idea',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    playerId: _player.id,
    subjectTag: 'player',
    lyrics: 'Saka lyrics',
    tuneName: 'Traditional',
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    score: 4,
    createdBy: status == 'canonical' ? 'system' : 'fan-1',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

Widget _wrap({
  required _ChantRepository repository,
  User? user,
  ValueChanged<RouteSettings>? onRoute,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      chantRepositoryProvider.overrideWithValue(repository),
      voteRepositoryProvider.overrideWithValue(_VoteRepository()),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: const PlayerScreen(
        player: _player,
        sportId: 'football',
        competitionId: 'premier-league',
      ),
      onGenerateRoute: (settings) {
        onRoute?.call(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('DESTINATION')),
        );
      },
    ),
  );
}

void main() {
  testWidgets('defaults to Songbook and starts a player-prefilled chant', (
    tester,
  ) async {
    final repository = _ChantRepository();
    addTearDown(repository.controller.close);
    RouteSettings? navigatedRoute;

    await tester.pumpWidget(
      _wrap(
        repository: repository,
        user: _User(),
        onRoute: (settings) => navigatedRoute = settings,
      ),
    );
    await tester.pump();
    repository.controller.add(
      ChantBrowseSnapshot(
        chants: [
          _chant(id: 'proven', status: 'canonical'),
          _chant(id: 'idea', status: 'community'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SAKA PROVEN'), findsOneWidget);
    expect(find.text('SAKA IDEA'), findsNothing);

    await tester.tap(find.text('CHANT LAB'));
    await tester.pumpAndSettle();
    expect(find.text('SAKA IDEA'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'START A CHANT'),
    );
    await tester.pumpAndSettle();
    expect(navigatedRoute?.name, AppRouter.submitChant);
    expect(navigatedRoute?.arguments, {
      'teamId': 'arsenal',
      'sportId': 'football',
      'competitionId': 'premier-league',
      'playerId': 'saka',
    });
  });

  testWidgets('signed-out empty Lab gives guidance without a write control', (
    tester,
  ) async {
    final repository = _ChantRepository();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_wrap(repository: repository));
    await tester.pump();
    repository.controller.add(ChantBrowseSnapshot(chants: const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHANT LAB'));
    await tester.pumpAndSettle();

    expect(
      find.text('No ideas yet. Sign in to start a chant for Bukayo Saka.'),
      findsOneWidget,
    );
    expect(find.text('START A CHANT'), findsNothing);
  });

  testWidgets('shows a full error only when no chant data is usable', (
    tester,
  ) async {
    final repository = _ChantRepository();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_wrap(repository: repository));
    await tester.pump();
    repository.controller.addError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(find.text('SOMETHING WENT WRONG'), findsOneWidget);
    expect(find.text('SONGBOOK'), findsOneWidget);
  });

  testWidgets('retains the last usable chants after a later stream error', (
    tester,
  ) async {
    final repository = _ChantRepository();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_wrap(repository: repository));
    await tester.pump();
    repository.controller.add(
      ChantBrowseSnapshot(
        chants: [_chant(id: 'proven', status: 'canonical')],
      ),
    );
    await tester.pumpAndSettle();
    repository.controller.addError(StateError('reconnect failed'));
    await tester.pumpAndSettle();

    expect(find.text('SAKA PROVEN'), findsOneWidget);
    expect(find.text('LAST LOADED CHANTS'), findsOneWidget);
    expect(find.text('SOMETHING WENT WRONG'), findsNothing);
  });
}
