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

    test('confirmWrite keeps delta until server score arrives', () {
      state.applyVote(1);
      expect(state.displayScore, 11);

      state.confirmWrite();
      // Delta stays: server score has not updated yet (CF lag)
      expect(state.displayScore, 11);
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

      // Write completes: delta stays +1, confirmed still null
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

    // ---- B2: reproduce the reported bug ----
    // Simulates the real flow: tap UP, write completes (local), server score
    // has NOT arrived yet (Cloud Function lag), tap UP again. The bug causes
    // the display to go negative because confirmWrite prematurely collapses
    // the optimistic state while serverScore is still stale.
    test('BUG: up-tap after confirmed write with stale server score must not go negative', () {
      state = OptimisticVoteState(serverScore: 0);

      // 1. Tap UP
      state.applyVote(1);
      expect(state.displayScore, 1, reason: 'optimistic +1');

      // 2. Write completes locally (CF has not run yet, server score still 0)
      state.confirmWrite();
      // After confirmWrite, display must still show 1, not snap back to 0
      expect(state.displayScore, 1,
          reason: 'must not snap back before server score arrives');

      // 3. Tap UP again (toggle off) while server score is still stale
      state.applyVote(1);
      // Should be 0 (toggled off, back to baseline), never negative
      expect(state.displayScore, 0,
          reason: 'toggle off must return to baseline, not go negative');
      expect(state.displayScore >= 0, true,
          reason: 'up-tap must never produce a negative score');
    });

    test('BUG: three up-taps with confirmWrite between each must not drift', () {
      state = OptimisticVoteState(serverScore: 0);

      // Tap 1: UP
      state.applyVote(1);
      expect(state.displayScore, 1);
      state.confirmWrite();
      // Must hold at 1 until server score arrives
      expect(state.displayScore, 1, reason: 'hold after first confirm');

      // Tap 2: UP (toggle off)
      state.applyVote(1);
      expect(state.displayScore, 0, reason: 'toggle off');
      state.confirmWrite();
      expect(state.displayScore, 0, reason: 'hold after second confirm');

      // Tap 3: UP (toggle on)
      state.applyVote(1);
      expect(state.displayScore, 1, reason: 'toggle on again');
    });

    test('BUG: up then down after confirmWrite stays correct', () {
      state = OptimisticVoteState(serverScore: 0);

      // Tap UP
      state.applyVote(1);
      expect(state.displayScore, 1);
      state.confirmWrite();
      expect(state.displayScore, 1, reason: 'hold at 1');

      // Tap DOWN (should go to -1 from baseline 0, not -2)
      state.applyVote(-1);
      expect(state.displayScore, -1,
          reason: 'net -1 from baseline, not compounded');
    });

    test('BUG: after stream confirms, delta is exactly 0', () {
      state = OptimisticVoteState(serverScore: 0);

      state.applyVote(1);
      state.confirmWrite();
      // Server score arrives
      state.reconcileServerScore(1);
      expect(state.displayScore, 1);
      expect(state.optimisticDelta, 0, reason: 'delta must collapse to 0');
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

    test('busy guard: applyVote while busy keeps busy true and updates intent', () {
      // First tap sets busy
      state.applyVote(1);
      expect(state.busy, true);
      expect(state.userVote, 1);
      expect(state.displayScore, 11);

      // Second tap while busy: busy stays true, intent updates
      state.applyVote(-1);
      expect(state.busy, true, reason: 'busy must stay true');
      expect(state.userVote, -1, reason: 'intent must reflect latest tap');
      expect(state.displayScore, 9,
          reason: 'display must reflect latest intent');
    });

    test('busy guard: rapid burst while busy always settles within one-vote range', () {
      // Simulate a burst of 10 rapid taps alternating up/down while busy
      state.applyVote(1);   // busy=true
      state.applyVote(-1);
      state.applyVote(1);
      state.applyVote(-1);
      state.applyVote(1);
      state.applyVote(-1);
      state.applyVote(1);
      state.applyVote(-1);
      state.applyVote(1);
      state.applyVote(-1);

      expect(state.busy, true);
      expect(state.userVote, -1);
      // optimisticDelta must be within one vote of confirmedVote (null)
      expect(state.optimisticDelta, -1);
      expect(state.displayScore, 9);
    });
  });
}
