import 'dart:async';
import 'dart:io';

import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/models/vote.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/presentation/browse/chant_call_up_card.dart';
import 'package:chants/presentation/browse/player_screen.dart';
import 'package:chants/presentation/browse/team_screen.dart';
import 'package:chants/presentation/submit/submit_chant_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../data/services/chant_call_ups_test.dart' show chantFor;
import '../../helpers/tolerant_golden_file_comparator.dart';

const _team = Team(
  id: 'test-club',
  name: 'Test United',
  sportId: 'football',
  competitionId: 'test-league',
);
const _players = [
  Player(id: 'alex', teamId: 'test-club', name: 'Alex Morgan'),
  Player(id: 'jamie', teamId: 'test-club', name: 'Jamie Taylor'),
];

class _User extends Mock implements User {
  @override
  String get uid => 'test-user';
}

class _Chants extends Mock implements ChantRepository {
  final controller = StreamController<ChantBrowseSnapshot>.broadcast();
  final created = <Chant>[];
  Completer<void>? submission;
  int teamSubscriptions = 0;
  @override
  Stream<ChantBrowseSnapshot> teamBrowseStream({required String teamId}) {
    expect(teamId, _team.id);
    teamSubscriptions++;
    return controller.stream;
  }

  @override
  Stream<ChantBrowseSnapshot> playerBrowseStream({required String playerId}) =>
      Stream.value(
        ChantBrowseSnapshot(
          chants: created.where((c) => c.playerId == playerId),
        ),
      );
  @override
  Future<List<Chant>> visibleChantsForTeamOnce({
    required String teamId,
  }) async => [];
  @override
  Future<void> createChant(Chant chant) async {
    await submission?.future;
    created.add(chant.copyWith(id: 'test-created'));
    controller.add(ChantBrowseSnapshot(chants: created));
  }
}

class _Players extends Mock implements PlayerRepository {
  final controller = StreamController<PlayerBrowseSnapshot>.broadcast();
  List<Player> listed = _players;
  int teamSubscriptions = 0;
  void emit({bool cached = false, bool pending = false}) {
    controller.add(
      PlayerBrowseSnapshot(
        players: listed,
        isFromCache: cached,
        hasPendingWrites: pending,
      ),
    );
  }

  @override
  Stream<PlayerBrowseSnapshot> teamBrowseStream({required String teamId}) {
    expect(teamId, _team.id);
    teamSubscriptions++;
    return controller.stream;
  }

  @override
  Stream<List<Player>> playersForTeamStream({required String teamId}) =>
      Stream.value(listed);
}

class _Votes extends Mock implements VoteRepository {
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async => null;
}

class _Harness {
  final chants = _Chants();
  final players = _Players();
  final routes = <RouteSettings>[];
  final navigator = GlobalKey<NavigatorState>();

  _Harness() {
    addTearDown(() {
      if (!chants.controller.isClosed) return chants.controller.close();
    });
    addTearDown(() {
      if (!players.controller.isClosed) return players.controller.close();
    });
  }

  Widget app({bool signedIn = false, double scale = 1, Widget? home}) =>
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(signedIn ? _User() : null),
          ),
          chantRepositoryProvider.overrideWithValue(chants),
          playerRepositoryProvider.overrideWithValue(players),
          voteRepositoryProvider.overrideWithValue(_Votes()),
          savedSongbookProvider.overrideWith(
            (ref, uid) async => SavedSongbook.empty(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigator,
          theme: ChantTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home ?? const TeamScreen(team: _team),
          onGenerateRoute: (settings) {
            routes.add(settings);
            if (settings.name == AppRouter.signIn) {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: Text('SIGN IN DESTINATION')),
              );
            }
            return AppRouter.onGenerateRoute(settings);
          },
        ),
      );

  Future<void> load(
    WidgetTester tester, {
    bool signedIn = false,
    double scale = 1,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(signedIn: signedIn, scale: scale));
    await tester.pump();
    chants.controller.add(ChantBrowseSnapshot(chants: []));
    players.emit();
    await tester.pumpAndSettle();
  }
}

Future<void> _fill(WidgetTester tester, {bool switchToClub = false}) async {
  await tester.tap(find.text('I made this'));
  await tester.enterText(
    find.byKey(const Key('chant-title-field')),
    'Test idea',
  );
  await tester.enterText(
    find.byKey(const Key('chant-lyrics-field')),
    'Synthetic test words',
  );
  await tester.enterText(
    find.byKey(const Key('chant-tune-field')),
    'Test tune',
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final scroll = find.byType(Scrollable).first;
  if (switchToClub) {
    await tester.scrollUntilVisible(find.text('Club'), 200, scrollable: scroll);
    await tester.tap(find.text('Club'));
  }
  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'SUBMIT'),
    250,
    scrollable: scroll,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'SUBMIT'));
  await tester.pumpAndSettle();
  expect(
    find.widgetWithText(FilledButton, 'SUBMIT').hitTestable(),
    findsOneWidget,
  );
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  testWidgets(
    'live spotlight cycles locally, survives tabs and excludes new chants',
    (tester) async {
      final h = _Harness();
      await h.load(tester);
      expect(find.text('ALEX MORGAN'), findsOneWidget);
      expect(
        find.text(
          'No chant for them at Test United in Chants yet. '
          'Funny or full of heart, start with the words.',
        ),
        findsOneWidget,
      );
      expect(find.text('TERRACE PROVEN'), findsOneWidget);
      h.players.listed = [
        const Player(id: 'aaron', teamId: 'test-club', name: 'Aaron Test'),
        ..._players,
      ];
      h.players.emit();
      await tester.pumpAndSettle();
      expect(find.text('ALEX MORGAN'), findsOneWidget);
      h.players.listed = _players;
      h.players.emit();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('call-up-next')));
      await tester.pumpAndSettle();
      expect(find.text('JAMIE TAYLOR'), findsOneWidget);
      await tester.tap(find.text('CHANT LAB'));
      await tester.pumpAndSettle();
      expect(find.text('JAMIE TAYLOR'), findsOneWidget);
      h.chants.controller.add(ChantBrowseSnapshot(chants: [chantFor('jamie')]));
      await tester.pumpAndSettle();
      expect(find.text('ALEX MORGAN'), findsOneWidget);
      expect(find.byKey(const Key('call-up-next')), findsNothing);
      h.players.listed = [_players.last];
      h.players.emit();
      await tester.pumpAndSettle();
      expect(find.byType(ChantCallUpCard), findsNothing);
      expect(h.chants.teamSubscriptions, 1);
      expect(h.players.teamSubscriptions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no absence claim until both snapshots are fresh, settled and active',
    (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.app());
      await tester.pump();
      expect(find.byType(ChantCallUpCard), findsNothing);
      h.chants.controller.add(ChantBrowseSnapshot(chants: []));
      await tester.pump();
      expect(find.byType(ChantCallUpCard), findsNothing);
      for (final phase in [
        'squad-cache',
        'squad-pending',
        'chant-cache',
        'chant-pending',
        'squad-error',
        'chant-error',
      ]) {
        h.players.emit(
          cached: phase == 'squad-cache',
          pending: phase == 'squad-pending',
        );
        h.chants.controller.add(
          ChantBrowseSnapshot(
            chants: [],
            isFromCache: phase == 'chant-cache',
            hasPendingWrites: phase == 'chant-pending',
          ),
        );
        if (phase == 'squad-error') {
          h.players.controller.addError(StateError('offline'));
        }
        if (phase == 'chant-error') {
          h.chants.controller.addError(StateError('offline'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ChantCallUpCard), findsNothing, reason: phase);
        h.players.emit();
        h.chants.controller.add(ChantBrowseSnapshot(chants: []));
        await tester.pumpAndSettle();
        expect(
          find.byType(ChantCallUpCard),
          findsOneWidget,
          reason: 'recovery from $phase',
        );
      }
      unawaited(h.players.controller.close());
      await tester.pumpAndSettle();
      expect(find.byType(ChantCallUpCard), findsNothing);
    },
  );

  testWidgets(
    'closed chant stream removes the claim and a stale callback cannot open a form',
    (tester) async {
      final h = _Harness();
      await h.load(tester, signedIn: true);
      final oldAction = tester
          .widget<FilledButton>(find.byKey(const Key('call-up-write')))
          .onPressed!;
      unawaited(h.chants.controller.close());
      await tester.pumpAndSettle();
      expect(find.byType(ChantCallUpCard), findsNothing);
      oldAction();
      await tester.pumpAndSettle();
      expect(h.routes, isEmpty);
    },
  );

  testWidgets('signed-out invitation goes to sign-in, not direct submission', (
    tester,
  ) async {
    final h = _Harness();
    await h.load(tester);
    await tester.tap(find.text('SIGN IN TO WRITE'));
    await tester.pumpAndSettle();
    expect(h.routes.single.name, AppRouter.signIn);
    expect(h.chants.created, isEmpty);
  });

  for (final switchToClub in [false, true]) {
    testWidgets(
      'actual prefilled form follows acknowledged subject (club=$switchToClub)',
      (tester) async {
        final h = _Harness();
        await h.load(tester, signedIn: true);
        await tester.tap(find.byKey(const Key('call-up-write')));
        await tester.pumpAndSettle();
        final form = tester.widget<SubmitChantScreen>(
          find.byType(SubmitChantScreen),
        );
        expect(
          (
            form.teamId,
            form.sportId,
            form.competitionId,
            form.prefilledPlayerId,
          ),
          (_team.id, _team.sportId, _team.competitionId, 'alex'),
        );
        expect(
          tester
              .widget<FormField<ChantOrigin>>(
                find.byKey(const Key('chant-origin-field')),
              )
              .initialValue,
          isNull,
        );
        await _fill(tester, switchToClub: switchToClub);
        h.chants.submission = Completer<void>();
        await tester.tap(find.widgetWithText(FilledButton, 'SUBMIT'));
        await tester.pump();
        expect(find.byType(SubmitChantScreen), findsOneWidget);
        expect(h.routes.length, 1);
        h.chants.submission!.complete();
        await tester.pumpAndSettle();
        final created = h.chants.created.single;
        expect(created.origin, ChantOrigin.originalIdea);
        expect(created.status, 'community');
        expect(created.playerId, switchToClub ? isNull : 'alex');
        if (switchToClub) {
          expect(find.byType(PlayerScreen), findsNothing);
          expect(h.routes.length, 1);
        } else {
          expect(
            tester.widget<PlayerScreen>(find.byType(PlayerScreen)).openChantLab,
            isTrue,
          );
          expect(h.routes.last.name, AppRouter.player);
        }
        expect(find.text('TEST IDEA'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('player leaving during acknowledgement returns to club Lab', (
    tester,
  ) async {
    final h = _Harness();
    await h.load(tester, signedIn: true);
    await tester.tap(find.byKey(const Key('call-up-write')));
    await tester.pumpAndSettle();
    await _fill(tester);
    h.chants.submission = Completer<void>();
    await tester.tap(find.widgetWithText(FilledButton, 'SUBMIT'));
    await tester.pump();
    h.players.listed = [];
    h.players.emit();
    await tester.pump();
    h.chants.submission!.complete();
    await tester.pumpAndSettle();
    expect(h.chants.created.single.playerId, 'alex');
    expect(find.byType(PlayerScreen), findsNothing);
    expect(find.text('TEST IDEA'), findsOneWidget);
    expect(h.routes.length, 1);
  });

  testWidgets(
    'disposed club cannot continue navigation after acknowledged submission',
    (tester) async {
      final h = _Harness();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        h.app(
          signedIn: true,
          home: const Scaffold(body: Text('SAFE DESTINATION')),
        ),
      );
      final clubRoute = MaterialPageRoute<void>(
        builder: (_) => const TeamScreen(team: _team),
      );
      unawaited(h.navigator.currentState!.push(clubRoute));
      await tester.pump();
      h.chants.controller.add(ChantBrowseSnapshot(chants: []));
      h.players.emit();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('call-up-write')));
      await tester.pumpAndSettle();
      await _fill(tester);
      h.chants.submission = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'SUBMIT'));
      await tester.pump();
      h.navigator.currentState!.removeRoute(clubRoute);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TeamScreen, skipOffstage: false), findsNothing);
      h.chants.submission!.complete();
      await tester.pumpAndSettle();
      expect(find.text('SAFE DESTINATION'), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed create retains form; cancelling never opens player Chant Lab',
    (tester) async {
      final h = _Harness();
      await h.load(tester, signedIn: true);
      await tester.tap(find.byKey(const Key('call-up-write')));
      await tester.pumpAndSettle();
      await _fill(tester);
      h.chants.submission = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'SUBMIT'));
      await tester.pump();
      h.chants.submission!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byType(SubmitChantScreen), findsOneWidget);
      expect(h.chants.created, isEmpty);
      expect(
        find.textContaining('Could not submit your chant'),
        findsOneWidget,
      );
      h.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsNothing);
      expect(h.routes.length, 1);
      expect(find.text('TERRACE PROVEN'), findsOneWidget);
    },
  );

  testWidgets(
    'call-up UI is labelled, touchable and scrollable at 320 and 1.8x text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      try {
        final h = _Harness();
        h.players.listed = [
          const Player(
            id: 'long',
            teamId: 'test-club',
            name: 'Alexandria Long-Double-Barrelled Footballer',
          ),
          _players.last,
        ];
        await h.load(tester, scale: 1.8, size: const Size(320, 844));
        expect(tester.takeException(), isNull);
        final action = find.byKey(const Key('call-up-write'));
        await tester.scrollUntilVisible(
          action,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(find.bySemanticsLabel('SIGN IN TO WRITE'), findsOneWidget);
        final next = find.byKey(const Key('call-up-next'));
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        expect(tester.getRect(next).bottom, lessThanOrEqualTo(844));
        expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('JAMIE TAYLOR'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final viewport in [
    (size: const Size(390, 844), scale: 1.0, file: 'club_call_up.png'),
    (
      size: const Size(320, 844),
      scale: 1.8,
      file: 'club_call_up_large_text.png',
    ),
  ]) {
    testWidgets('club call-up golden ${viewport.file}', (tester) async {
      installTolerantGoldenComparator(
        testFile: Uri.base.resolve(
          'test/presentation/browse/chant_call_up_test.dart',
        ),
      );
      for (final font in {
        'Nunito': 'assets/fonts/Nunito-Variable.ttf',
        'Anton': 'assets/fonts/Anton-Regular.ttf',
        'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(
          font.key,
        )..addFont(rootBundle.load(font.value))).load();
      }
      final h = _Harness();
      await h.load(
        tester,
        signedIn: true,
        scale: viewport.scale,
        size: viewport.size,
      );
      expect(find.text('CHANT CALL-UP'), findsOneWidget);
      expect(find.text('WRITE THIS CHANT'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/${Platform.isLinux ? 'linux/' : ''}${viewport.file}',
        ),
      );
    });
  }
}
