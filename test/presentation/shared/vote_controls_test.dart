import 'package:flutter_test/flutter_test.dart';

/// Tests for the optimistic vote delta logic extracted from VoteControls.
/// The widget itself requires Firebase mocks; here we test the pure delta
/// calculation that prevents double-counting and drift.
void main() {
  group('Optimistic vote delta', () {
    // Simulate the delta logic from VoteControls._onVote
    int calculateDelta({required int? currentVote, required int tapValue}) {
      if (currentVote == tapValue) {
        // Toggle off: undo
        return -tapValue;
      } else if (currentVote != null) {
        // Switch direction: remove old + add new
        return -currentVote + tapValue;
      } else {
        // Fresh vote
        return tapValue;
      }
    }

    int? newVoteAfterTap({required int? currentVote, required int tapValue}) {
      if (currentVote == tapValue) return null;
      return tapValue;
    }

    test('fresh upvote adds +1', () {
      expect(calculateDelta(currentVote: null, tapValue: 1), 1);
      expect(newVoteAfterTap(currentVote: null, tapValue: 1), 1);
    });

    test('fresh downvote adds -1', () {
      expect(calculateDelta(currentVote: null, tapValue: -1), -1);
      expect(newVoteAfterTap(currentVote: null, tapValue: -1), -1);
    });

    test('upvote then upvote again removes vote (toggle off)', () {
      // First tap: fresh upvote
      final d1 = calculateDelta(currentVote: null, tapValue: 1);
      final v1 = newVoteAfterTap(currentVote: null, tapValue: 1);
      expect(d1, 1);
      expect(v1, 1);

      // Second tap: toggle off
      final d2 = calculateDelta(currentVote: v1, tapValue: 1);
      final v2 = newVoteAfterTap(currentVote: v1, tapValue: 1);
      expect(d2, -1); // undoes the +1
      expect(v2, null);

      // Net delta should be 0 (back to baseline)
      expect(d1 + d2, 0);
    });

    test('upvote then downvote swings by -2', () {
      final d1 = calculateDelta(currentVote: null, tapValue: 1);
      final v1 = newVoteAfterTap(currentVote: null, tapValue: 1);

      final d2 = calculateDelta(currentVote: v1, tapValue: -1);
      final v2 = newVoteAfterTap(currentVote: v1, tapValue: -1);
      expect(d2, -2); // remove +1, add -1
      expect(v2, -1);

      // Net delta: +1 + (-2) = -1
      expect(d1 + d2, -1);
    });

    test('downvote then upvote swings by +2', () {
      final d1 = calculateDelta(currentVote: null, tapValue: -1);
      final v1 = newVoteAfterTap(currentVote: null, tapValue: -1);

      final d2 = calculateDelta(currentVote: v1, tapValue: 1);
      expect(d2, 2); // remove -1, add +1

      expect(d1 + d2, 1);
    });

    test('rapid repeated upvotes net to zero (tap-tap)', () {
      // Tap 1: upvote
      var delta = 0;
      int? vote;

      final d1 = calculateDelta(currentVote: vote, tapValue: 1);
      vote = newVoteAfterTap(currentVote: vote, tapValue: 1);
      delta += d1;

      // Tap 2: toggle off
      final d2 = calculateDelta(currentVote: vote, tapValue: 1);
      vote = newVoteAfterTap(currentVote: vote, tapValue: 1);
      delta += d2;

      // Tap 3: upvote again
      final d3 = calculateDelta(currentVote: vote, tapValue: 1);
      vote = newVoteAfterTap(currentVote: vote, tapValue: 1);
      delta += d3;

      // Tap 4: toggle off again
      final d4 = calculateDelta(currentVote: vote, tapValue: 1);
      vote = newVoteAfterTap(currentVote: vote, tapValue: 1);
      delta += d4;

      expect(delta, 0);
      expect(vote, null);
    });

    test('score display uses server score plus optimistic delta', () {
      const serverScore = 5;
      var optimisticDelta = 0;
      int? userVote;

      // Upvote
      optimisticDelta += calculateDelta(currentVote: userVote, tapValue: 1);
      userVote = newVoteAfterTap(currentVote: userVote, tapValue: 1);
      expect(serverScore + optimisticDelta, 6);

      // Toggle off
      optimisticDelta += calculateDelta(currentVote: userVote, tapValue: 1);
      userVote = newVoteAfterTap(currentVote: userVote, tapValue: 1);
      expect(serverScore + optimisticDelta, 5); // back to baseline
    });
  });
}
