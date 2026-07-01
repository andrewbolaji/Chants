import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/vote.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

// --- Fakes (write boundary only, no logic reimplementation) ---

class _MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-1';
}

class _FakeVoteRepository implements VoteRepository {
  Vote? nextVote;

  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async {
    return nextVote;
  }

  @override
  Future<void> castVote({
    required String userId,
    required String chantId,
    required int value,
  }) async {
    // resolves immediately, no network
  }

  @override
  Future<void> removeVote({
    required String userId,
    required String chantId,
  }) async {
    // resolves immediately, no network
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Helpers ---

Chant _makeChant({int score = 5}) {
  return Chant(
    id: 'test-chant-1',
    title: 'Test Chant',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'club',
    lyrics: 'La la la',
    tuneName: 'Traditional',
    mediaType: 'none',
    status: 'canonical',
    realOrParody: 'real',
    createdBy: 'system',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    score: score,
  );
}

Vote _makeVote({required int value, int? appliedValue}) {
  return Vote(
    id: 'test-user-1_test-chant-1',
    chantId: 'test-chant-1',
    userId: 'test-user-1',
    value: value,
    createdAt: DateTime(2026, 7, 1),
    appliedValue: appliedValue,
  );
}

void main() {
  final fakeUser = _MockUser();
  final fakeVoteRepo = _FakeVoteRepository();

  /// Wraps VoteControls in the required Riverpod + Material scaffolding,
  /// overriding only the auth and vote-repository providers.
  /// The [chant] param lets us re-pump with a new score to simulate
  /// the server stream (didUpdateWidget fires, calling reconcileServerScore).
  Widget wrap(Chant chant) {
    return ProviderScope(
      overrides: [
        voteRepositoryProvider.overrideWithValue(fakeVoteRepo),
        authStateProvider.overrideWith(
          (ref) => Stream.value(fakeUser as User?),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: VoteControls(chant: chant),
        ),
      ),
    );
  }

  /// Reads the rendered score text from the real widget tree.
  String renderedScore(WidgetTester tester) {
    // The score is the Text widget inside the middle SizedBox of the Row,
    // with SpaceMono font. Find by the style to be precise.
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final tw in textWidgets) {
      if (tw.style?.fontFamily == 'SpaceMono') return tw.data!;
    }
    fail('Could not find the SpaceMono score Text in the widget tree');
  }

  group('VoteControls widget', () {
    testWidgets(
      'a. tap Upvote: shows start+1 and holds after write settles',
      (tester) async {
        final chant = _makeChant(score: 5);
        await tester.pumpWidget(wrap(chant));
        // Let _loadUserVote future complete and set _loaded = true
        await tester.pumpAndSettle();

        expect(renderedScore(tester), '5', reason: 'initial score');

        // Tap Upvote
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pump(); // optimistic update
        expect(renderedScore(tester), '6', reason: 'optimistic +1');

        // Let the async castVote future complete (confirmWrite fires)
        await tester.pumpAndSettle();
        // Score MUST hold at 6, NOT snap back to 5
        expect(renderedScore(tester), '6',
            reason: 'must hold after write settles, not snap back');
      },
    );

    testWidgets(
      'b. server score arrival (re-pump): no double count',
      (tester) async {
        final chant = _makeChant(score: 5);
        await tester.pumpWidget(wrap(chant));
        await tester.pumpAndSettle();

        // Tap Upvote
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '6');

        // Simulate Cloud Function: parent re-pumps with score=6
        final updatedChant = _makeChant(score: 6);
        await tester.pumpWidget(wrap(updatedChant));
        await tester.pumpAndSettle();
        // Must show 6, not 7 (double count)
        expect(renderedScore(tester), '6',
            reason: 'must not double-count server confirmation');
      },
    );

    testWidgets(
      'c. toggle off before server update: returns to start, never negative',
      (tester) async {
        final chant = _makeChant(score: 5);
        await tester.pumpWidget(wrap(chant));
        await tester.pumpAndSettle();

        // Tap Upvote (on)
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '6');

        // Tap Upvote again (toggle off), no server update yet
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '5',
            reason: 'toggle off returns to start');
        expect(int.parse(renderedScore(tester)) >= 0, true,
            reason: 'up-tap must never produce a negative score');
      },
    );

    testWidgets(
      'd. third up-tap shows start+1 again',
      (tester) async {
        final chant = _makeChant(score: 5);
        await tester.pumpWidget(wrap(chant));
        await tester.pumpAndSettle();

        // Tap 1: UP (on)
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '6');

        // Tap 2: UP (off)
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '5');

        // Tap 3: UP (on again)
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '6',
            reason: 'third tap must re-show start+1');
      },
    );

    testWidgets(
      'e. up then down: net -1, down arrow shows red active state',
      (tester) async {
        final chant = _makeChant(score: 5);
        await tester.pumpWidget(wrap(chant));
        await tester.pumpAndSettle();

        // Tap Upvote
        await tester.tap(find.bySemanticsLabel('Upvote'));
        await tester.pumpAndSettle();
        expect(renderedScore(tester), '6');

        // Tap Downvote (switches from up to down: net -2 swing)
        await tester.tap(find.bySemanticsLabel('Downvote'));
        await tester.pumpAndSettle();
        // start(5) + delta(from null confirmed to -1) = 5 + (-1) = 4
        // But since we went up first without server confirm, confirmed is
        // still null, so switching from up(1) to down(-1): delta = -1 - 0 = -1
        // display = 5 + (-1) = 4
        expect(renderedScore(tester), '4',
            reason: 'up then down is net one below start');

        // Down arrow should show the error/red active color
        final downIcon = tester.widget<Icon>(
          find.descendant(
            of: find.bySemanticsLabel('Downvote'),
            matching: find.byType(Icon),
          ),
        );
        // The IconButton applies color to the icon; read it from the
        // IconButton's color property instead
        final downButton = tester.widget<IconButton>(
          find.descendant(
            of: find.bySemanticsLabel('Downvote'),
            matching: find.byType(IconButton),
          ),
        );
        expect(downButton.color, AppColors.error,
            reason: 'down arrow must show red active state');
      },
    );
  });

  // --- appliedValue disambiguation tests (T1-T7) ---

  group('VoteControls appliedValue disambiguation', () {
    late _FakeVoteRepository repo;

    setUp(() {
      repo = _FakeVoteRepository();
    });

    /// Shared overrides used by all helpers below.
    List<Override> overrides() => [
          voteRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith(
            (ref) => Stream.value(fakeUser as User?),
          ),
        ];

    /// Pumps VoteControls with a [ValueNotifier] so the test can swap the
    /// chant (simulating a stream-delivered score update via didUpdateWidget).
    /// Uses a two-phase pump: first warms the auth stream, then creates
    /// VoteControls so _loadUserVote sees the user.
    Future<ValueNotifier<Chant>> pumpWithNotifier(
      WidgetTester tester, {
      required Chant chant,
    }) async {
      final notifier = ValueNotifier<Chant>(chant);
      final keyNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: keyNotifier,
                builder: (_, k, __) => ValueListenableBuilder<Chant>(
                  valueListenable: notifier,
                  builder: (_, c, __) =>
                      VoteControls(key: ValueKey(k), chant: c),
                ),
              ),
            ),
          ),
        ),
      );

      // Phase 1: let the auth stream emit so the provider is Data.
      await tester.pumpAndSettle();

      // Phase 2: new key forces a fresh State whose _loadUserVote
      // can now read the auth value.
      keyNotifier.value = 1;
      await tester.pumpAndSettle();

      return notifier;
    }

    /// Pumps a fresh VoteControls (new key forces new State).
    /// Same two-phase pattern for auth warmup.
    Future<void> pumpFresh(
      WidgetTester tester, {
      required Chant chant,
      required String keyLabel,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(
            home: Scaffold(
              body: VoteControls(
                key: ValueKey('warmup-$keyLabel'),
                chant: chant,
              ),
            ),
          ),
        ),
      );
      // Warm up auth stream.
      await tester.pumpAndSettle();

      // Fresh State that sees the user.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(
            home: Scaffold(
              body: VoteControls(
                key: ValueKey(keyLabel),
                chant: chant,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // T1: Case B on load (stale score, persisted downvote, CF not caught up)
    testWidgets(
      'T1: Case B load shows vote reflected, stream arrival stable',
      (tester) async {
        repo.nextVote = _makeVote(value: -1, appliedValue: null);

        final notifier = await pumpWithNotifier(
          tester,
          chant: _makeChant(score: 0),
        );

        // Case B: serverScore 0 does not include the vote. Must show -1.
        expect(renderedScore(tester), '-1');

        // Stream delivers the CF-updated score.
        notifier.value = _makeChant(score: -1);
        await tester.pumpAndSettle();

        // Must stay at -1, no drift.
        expect(renderedScore(tester), '-1');
      },
    );

    // T2: Case A on load (caught-up score, persisted downvote)
    testWidgets(
      'T2: Case A load shows correct score, no double-count',
      (tester) async {
        repo.nextVote = _makeVote(value: -1, appliedValue: -1);

        await pumpWithNotifier(tester, chant: _makeChant(score: -1));

        // Case A: serverScore already includes the vote. Must show -1, not -2.
        expect(renderedScore(tester), '-1');
      },
    );

    // T3: Reported reproduction (vote, back out, re-enter)
    testWidgets(
      'T3: re-entry after vote shows correct score in both cases',
      (tester) async {
        // Phase 1: fresh chant, no prior vote.
        repo.nextVote = null;
        await pumpFresh(tester, chant: _makeChant(score: 0), keyLabel: 'p1');
        expect(renderedScore(tester), '0');

        // Tap downvote.
        await tester.tap(find.bySemanticsLabel('Downvote'));
        await tester.pump();
        expect(renderedScore(tester), '-1');

        // Phase 2: re-enter with CF NOT caught up.
        repo.nextVote = _makeVote(value: -1, appliedValue: null);
        await pumpFresh(
            tester, chant: _makeChant(score: 0), keyLabel: 'p2-b');
        expect(renderedScore(tester), '-1',
            reason: 'Case B re-entry must show vote, not stale 0');

        // Phase 3: re-enter with CF caught up.
        repo.nextVote = _makeVote(value: -1, appliedValue: -1);
        await pumpFresh(
            tester, chant: _makeChant(score: -1), keyLabel: 'p3-a');
        expect(renderedScore(tester), '-1',
            reason: 'Case A re-entry must show -1, not -2');
      },
    );

    // T4: Toggle after reload with persisted downvote (Case B)
    testWidgets(
      'T4: toggle after Case B reload never shows +1',
      (tester) async {
        repo.nextVote = _makeVote(value: -1, appliedValue: null);

        await pumpWithNotifier(tester, chant: _makeChant(score: 0));
        expect(renderedScore(tester), '-1');

        // Tap down (toggle off, removing the vote).
        await tester.tap(find.bySemanticsLabel('Downvote'));
        await tester.pump();
        expect(renderedScore(tester), '0',
            reason: 'toggle off returns to base, never +1');

        // Tap down again (re-apply).
        await tester.tap(find.bySemanticsLabel('Downvote'));
        await tester.pump();
        expect(renderedScore(tester), '-1');
      },
    );

    // T5: No-vote control (baseline)
    testWidgets(
      'T5: no persisted vote loads at plain score',
      (tester) async {
        repo.nextVote = null;
        await pumpWithNotifier(tester, chant: _makeChant(score: 7));
        expect(renderedScore(tester), '7');
      },
    );

    // T6: Vote flip with stale appliedValue
    testWidgets(
      'T6: flip from up to down with stale appliedValue',
      (tester) async {
        // User flipped from upvote to downvote, CF has not processed the flip.
        repo.nextVote = _makeVote(value: -1, appliedValue: 1);

        await pumpWithNotifier(tester, chant: _makeChant(score: 5));

        // delta = deltaForTransition(1, -1) = -2. display = 5 + (-2) = 3.
        expect(renderedScore(tester), '3');
      },
    );

    // T7: Cold load after a delete (vote removed, CF not caught up)
    testWidgets(
      'T7: delete window, stale then stream corrects',
      (tester) async {
        // Vote was removed (getUserVote returns null) but the chant score
        // still includes the old vote's effect (serverScore = -1).
        repo.nextVote = null;

        final notifier = await pumpWithNotifier(
          tester,
          chant: _makeChant(score: -1),
        );

        // No vote doc, so confirmedVote = null, delta = 0. Display = -1.
        // Temporarily wrong (true score is 0) but acceptable because:
        //   - No highlighted arrow, no toggle confusion.
        //   - On the stream-backed list and detail, the stream corrects it.
        expect(renderedScore(tester), '-1',
            reason: 'stale score before CF catches up on delete');

        // Stream delivers the CF-updated score (vote effect removed).
        notifier.value = _makeChant(score: 0);
        await tester.pumpAndSettle();

        expect(renderedScore(tester), '0',
            reason: 'stream corrects the delete window');

        // Verify it stays stable.
        await tester.pump(const Duration(seconds: 1));
        expect(renderedScore(tester), '0');
      },
    );
  });
}
