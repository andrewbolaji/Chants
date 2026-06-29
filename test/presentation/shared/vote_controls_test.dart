import 'package:flutter_test/flutter_test.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

/// Tests for OptimisticVoteState — the real reconciliation logic used by
/// VoteControls. Not a copy; exercises the same class the widget delegates to.
void main() {
  late OptimisticVoteState state;

  setUp(() {
    state = OptimisticVoteState(serverScore: 10);
  });

  group('OptimisticVoteState', () {
    test('initial display score equals server score', () {
      expect(state.displayScore, 10);
    });

    test('upvote shows +1 immediately', () {
      state.applyVote(1);
      expect(state.displayScore, 11);
      expect(state.userVote, 1);
    });

    test('downvote shows -1 immediately', () {
      state.applyVote(-1);
      expect(state.displayScore, 9);
      expect(state.userVote, -1);
    });

    test('tap up then tap up again returns to baseline (toggle off)', () {
      state.applyVote(1);
      expect(state.displayScore, 11);

      state.applyVote(1); // toggle off
      expect(state.displayScore, 10);
      expect(state.userVote, null);
    });

    test('tap up then tap down gives net -1 from baseline', () {
      state.applyVote(1);
      expect(state.displayScore, 11);

      state.applyVote(-1); // switch direction
      expect(state.displayScore, 9);
      expect(state.userVote, -1);
    });

    test('tap down then tap up gives net +1 from baseline', () {
      state.applyVote(-1);
      expect(state.displayScore, 9);

      state.applyVote(1);
      expect(state.displayScore, 11);
      expect(state.userVote, 1);
    });

    test('rapid repeated taps converge on correct value with no drift', () {
      // up, off, up, off, up, off, down, off
      state.applyVote(1);
      expect(state.displayScore, 11);
      state.applyVote(1);
      expect(state.displayScore, 10);
      state.applyVote(1);
      expect(state.displayScore, 11);
      state.applyVote(1);
      expect(state.displayScore, 10);
      state.applyVote(1);
      expect(state.displayScore, 11);
      state.applyVote(1);
      expect(state.displayScore, 10);
      state.applyVote(-1);
      expect(state.displayScore, 9);
      state.applyVote(-1);
      expect(state.displayScore, 10);
    });

    test('confirmWrite clears delta and updates confirmed state', () {
      state.applyVote(1);
      expect(state.displayScore, 11);

      state.confirmWrite();
      expect(state.displayScore, 10); // delta cleared, server hasn't updated
      expect(state.confirmedVote, 1);
      expect(state.busy, false);
    });

    test('server score arrival after confirmed write shows correct value', () {
      state.applyVote(1);
      state.confirmWrite();
      // Server now emits score=11 (reflects the upvote)
      state.reconcileServerScore(11);
      expect(state.displayScore, 11);
      expect(state.optimisticDelta, 0);
    });

    test('server score arrival does not double-count (the core bug)', () {
      // User upvotes: display=11, delta=1
      state.applyVote(1);
      expect(state.displayScore, 11);

      // Write completes: confirmed=1, delta=0
      state.confirmWrite();

      // Server emits 11 (already includes the vote)
      state.reconcileServerScore(11);
      // Must show 11, not 12
      expect(state.displayScore, 11);
      expect(state.optimisticDelta, 0);
    });

    test('server score during in-flight write preserves pending delta', () {
      // User upvotes: busy=true
      state.applyVote(1);
      expect(state.busy, true);
      expect(state.displayScore, 11);

      // Server emits a different score (e.g. another user voted, score=11)
      // but our write hasn't completed yet
      state.reconcileServerScore(11);
      // busy is still true, so delta is recomputed from confirmed(null)->user(1)=+1
      expect(state.displayScore, 12); // 11 (new server) + 1 (our pending)
      expect(state.optimisticDelta, 1);
    });

    test('revertWrite restores previous state', () {
      state.applyVote(1);
      expect(state.displayScore, 11);

      state.revertWrite(null, null); // revert to no vote
      expect(state.displayScore, 10);
      expect(state.userVote, null);
      expect(state.busy, false);
    });

    test('score can go negative', () {
      state = OptimisticVoteState(serverScore: 0);
      state.applyVote(-1);
      expect(state.displayScore, -1);
    });

    test('rapid up-down-up-down with no writes settles correctly', () {
      // Simulates rapid taps before any write completes
      state.applyVote(1);   // up: 11
      state.applyVote(-1);  // switch to down: 9
      state.applyVote(1);   // switch to up: 11
      state.applyVote(-1);  // switch to down: 9
      state.applyVote(-1);  // toggle off: 10

      expect(state.displayScore, 10);
      expect(state.userVote, null);
    });

    test('deltaForTransition covers all transitions', () {
      // none->up: +1
      expect(OptimisticVoteState.deltaForTransition(null, 1), 1);
      // none->down: -1
      expect(OptimisticVoteState.deltaForTransition(null, -1), -1);
      // up->none: -1
      expect(OptimisticVoteState.deltaForTransition(1, null), -1);
      // down->none: +1
      expect(OptimisticVoteState.deltaForTransition(-1, null), 1);
      // up->down: -2
      expect(OptimisticVoteState.deltaForTransition(1, -1), -2);
      // down->up: +2
      expect(OptimisticVoteState.deltaForTransition(-1, 1), 2);
    });

    test('pre-existing vote: user had upvote, taps down swings -2', () {
      state = OptimisticVoteState(
        serverScore: 10,
        userVote: 1,
        confirmedVote: 1,
      );
      state.applyVote(-1);
      expect(state.displayScore, 8); // 10 + ((-1) - 1) = 8
      expect(state.userVote, -1);
    });
  });
}
