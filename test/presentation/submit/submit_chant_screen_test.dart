import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/presentation/submit/submit_chant_screen.dart';
import 'package:mockito/mockito.dart';

class _MockUser extends Mock implements User {
  @override
  String get uid => 'user-1';
}

class _FakePlayerRepository extends Mock implements PlayerRepository {
  final Stream<List<Player>> players;

  _FakePlayerRepository([Stream<List<Player>>? players])
    : players = players ?? Stream.value(const []);

  @override
  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return players;
  }
}

class _FakeChantRepository extends Mock implements ChantRepository {
  List<Chant> candidates = [];
  Object? lookupError;
  Completer<List<Chant>>? lookupCompleter;
  final List<Chant> created = [];
  int lookups = 0;

  @override
  Future<List<Chant>> visibleChantsForTeamOnce({required String teamId}) {
    lookups++;
    if (lookupError != null) return Future.error(lookupError!);
    if (lookupCompleter != null) return lookupCompleter!.future;
    return Future.value(candidates);
  }

  @override
  Future<void> createChant(Chant chant) async {
    created.add(chant);
  }
}

Chant candidate() => Chant(
  id: 'existing',
  title: 'One Nil to the Arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  teamId: 'arsenal',
  subjectTag: 'club',
  lyrics: 'One nil to the Arsenal',
  tuneName: 'Go West',
  mediaType: 'none',
  status: 'canonical',
  chantType: 'sincere',
  createdBy: 'system',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget _wrap(
  _FakeChantRepository repository, {
  Stream<List<Player>>? players,
  String? prefilledPlayerId,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_MockUser())),
      chantRepositoryProvider.overrideWithValue(repository),
      playerRepositoryProvider.overrideWithValue(
        _FakePlayerRepository(players),
      ),
    ],
    child: MaterialApp(
      home: SubmitChantScreen(
        teamId: 'arsenal',
        sportId: 'football',
        competitionId: 'premier-league',
        prefilledPlayerId: prefilledPlayerId,
      ),
    ),
  );
}

Future<void> fillRequiredForm(
  WidgetTester tester, {
  bool chooseOrigin = true,
  String? evidence,
}) async {
  if (chooseOrigin) await tester.tap(find.text('I made this'));
  await tester.enterText(
    find.byKey(const Key('chant-title-field')),
    'One Nil to the Arsenal',
  );
  await tester.enterText(
    find.byKey(const Key('chant-lyrics-field')),
    'One nil to the Arsenal',
  );
  await tester.enterText(find.byKey(const Key('chant-tune-field')), 'Go West');
  final formScroll = find.byType(Scrollable).first;
  if (evidence != null) {
    await tester.scrollUntilVisible(
      find.byKey(const Key('chant-evidence-field')),
      400,
      scrollable: formScroll,
    );
    await tester.enterText(
      find.byKey(const Key('chant-evidence-field')),
      evidence,
    );
  }
  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'SUBMIT'),
    500,
    scrollable: formScroll,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('requires origin before lookup or create', (tester) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(tester, chooseOrigin: false);

    await tester.tap(find.text('SUBMIT'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('chant-origin-field')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose where this chant started.'), findsOneWidget);
    expect(repository.lookups, 0);
    expect(repository.created, isEmpty);
  });

  testWidgets('stores required origin with optional empty evidence', (
    tester,
  ) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(tester);

    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in before adding a chant.'), findsNothing);
    expect(repository.lookups, 1);
    expect(repository.created, hasLength(1));
    expect(repository.created.single.origin, ChantOrigin.originalIdea);
    expect(repository.created.single.evidence, isNull);
  });

  testWidgets('normalizes valid evidence before create', (tester) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(
      tester,
      evidence: 'https://youtu.be/dQw4w9WgXcQ?t=10',
    );

    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(
      repository.created.single.evidence?.url,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
  });

  testWidgets('invalid evidence retains the form and performs no lookup', (
    tester,
  ) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(
      tester,
      evidence: 'https://youtube.com.example.test/watch?v=dQw4w9WgXcQ',
    );

    await tester.tap(find.text('SUBMIT'));
    await tester.pump();
    expect(
      find.text('For v1, evidence links must be from YouTube or X.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('chant-title-field')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextFormField>(
      find.byKey(const Key('chant-title-field')),
    );
    expect(titleField.controller?.text, 'One Nil to the Arsenal');
    expect(repository.lookups, 0);
    expect(repository.created, isEmpty);
  });

  testWidgets('likely duplicate requires explicit continue before one write', (
    tester,
  ) async {
    final repository = _FakeChantRepository()..candidates = [candidate()];
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(tester);

    await tester.tap(find.text('SUBMIT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('IS IT ONE OF THESE?'), findsOneWidget);
    expect(find.text('VIEW CHANT'), findsOneWidget);
    expect(repository.created, isEmpty);

    await tester.tap(find.byKey(const Key('post-duplicate-anyway')));
    await tester.pumpAndSettle();
    expect(repository.created, hasLength(1));
  });

  testWidgets('going back from duplicate review writes nothing', (
    tester,
  ) async {
    final repository = _FakeChantRepository()..candidates = [candidate()];
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(tester);

    await tester.tap(find.text('SUBMIT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('GO BACK'));
    await tester.pumpAndSettle();

    expect(repository.created, isEmpty);
    expect(find.text('One Nil to the Arsenal'), findsWidgets);
    expect(find.text('SUBMIT'), findsOneWidget);
  });

  testWidgets('advisory lookup failure fails open to one create', (
    tester,
  ) async {
    final repository = _FakeChantRepository()
      ..lookupError = StateError('offline');
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(tester);

    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(repository.lookups, 1);
    expect(repository.created, hasLength(1));
  });

  testWidgets('repeated taps during lookup still produce one create', (
    tester,
  ) async {
    final repository = _FakeChantRepository()
      ..lookupCompleter = Completer<List<Chant>>();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    await fillRequiredForm(tester);

    await tester.tap(find.text('SUBMIT'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
    repository.lookupCompleter!.complete([]);
    await tester.pumpAndSettle();

    expect(repository.lookups, 1);
    expect(repository.created, hasLength(1));
  });

  testWidgets('missing prefilled Player clears without a dropdown assertion', (
    tester,
  ) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(
      _wrap(
        repository,
        prefilledPlayerId: 'moved-player',
        players: Stream.value(const [
          Player(id: 'current-player', teamId: 'arsenal', name: 'Current'),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('player-selection-notice')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'That player is no longer on this club list. Pick another player '
        'or choose a different subject.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player-selection-notice')), findsNothing);
  });

  testWidgets(
    'Player stream error explains recovery and allows subject switch',
    (tester) async {
      final repository = _FakeChantRepository();
      await tester.pumpWidget(
        _wrap(
          repository,
          prefilledPlayerId: 'player-1',
          players: Stream<List<Player>>.error(StateError('offline')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('player-load-error')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Could not load this club’s players. Try again when you are '
          'connected, or choose another subject.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Club'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-load-error')), findsNothing);
    },
  );
}
