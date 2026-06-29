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
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async {
    return null; // no pre-existing vote
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
}
