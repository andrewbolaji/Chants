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
  MediaQueryData? mediaQueryData,
}) {
  final screen = SubmitChantScreen(
    teamId: 'arsenal',
    sportId: 'football',
    competitionId: 'premier-league',
    prefilledPlayerId: prefilledPlayerId,
  );
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_MockUser())),
      chantRepositoryProvider.overrideWithValue(repository),
      playerRepositoryProvider.overrideWithValue(
        _FakePlayerRepository(players),
      ),
    ],
    child: MaterialApp(
      home: mediaQueryData == null
          ? screen
          : MediaQuery(data: mediaQueryData, child: screen),
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

  testWidgets('chant entry uses compact UI type and a sung-line cue', (
    tester,
  ) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    final titleField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('chant-title-field')),
        matching: find.byType(EditableText),
      ),
    );
    final lyricsField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('chant-lyrics-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(titleField.style.fontFamily, 'Nunito');
    expect(titleField.style.fontSize, 17);
    expect(lyricsField.style.fontFamily, 'Fraunces');
    expect(lyricsField.style.fontSize, 18);
    expect(lyricsField.minLines, 5);
    expect(lyricsField.maxLines, 10);
    expect(find.text('Use a new line for each sung line.'), findsOneWidget);
    expect(find.byKey(const Key('chant-lyrics-count')), findsOneWidget);
  });

  testWidgets('player picker is searchable and can close without a choice', (
    tester,
  ) async {
    final repository = _FakeChantRepository();
    await tester.pumpWidget(
      _wrap(
        repository,
        players: Stream.value(const [
          Player(id: 'ben', teamId: 'arsenal', name: 'Ben White'),
          Player(id: 'bukayo', teamId: 'arsenal', name: 'Bukayo Saka'),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Player'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('player-picker-field')),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('player-picker-field')));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE A PLAYER'), findsOneWidget);
    expect(find.byKey(const Key('player-picker-close')), findsOneWidget);

    await tester.tap(find.byKey(const Key('player-picker-close')));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE A PLAYER'), findsNothing);
    expect(find.text('Choose a player'), findsOneWidget);

    await tester.tap(find.byKey(const Key('player-picker-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('player-picker-search')),
      'saka',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ben White'), findsNothing);
    expect(find.text('Bukayo Saka'), findsOneWidget);

    await tester.tap(find.text('Bukayo Saka'));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE A PLAYER'), findsNothing);
    expect(find.text('Bukayo Saka'), findsOneWidget);
  });

  testWidgets('player picker keeps its final row above the keyboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final players = List.generate(
      20,
      (index) => Player(
        id: 'player-$index',
        teamId: 'arsenal',
        name: 'Player ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _wrap(
        _FakeChantRepository(),
        players: Stream.value(players),
        mediaQueryData: const MediaQueryData(
          size: Size(390, 844),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Player'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('player-picker-field')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('player-picker-field')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Player 20'),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('player-picker-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.text('Player 20')).bottom,
      lessThanOrEqualTo(544),
    );
    expect(tester.takeException(), isNull);
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
