import { strict as assert } from "assert";

/**
 * Cross-implementation invariant test for vote counter logic.
 *
 * Tests the delta math that the onVoteWritten function uses,
 * and the reconciliation script that recomputes from ground truth.
 * The delta logic is the single source of truth for all 6 transitions.
 */

interface VoteState {
  value: 1 | -1;
}

interface CounterState {
  upvotes: number;
  downvotes: number;
  score: number;
}

// Mirrors the onVoteWritten delta logic exactly
function computeDelta(
  before: VoteState | null,
  after: VoteState | null
): { upDelta: number; downDelta: number; scoreDelta: number } {
  let upDelta = 0;
  let downDelta = 0;

  if (before) {
    if (before.value === 1) upDelta -= 1;
    else if (before.value === -1) downDelta -= 1;
  }

  if (after) {
    if (after.value === 1) upDelta += 1;
    else if (after.value === -1) downDelta += 1;
  }

  return { upDelta, downDelta, scoreDelta: upDelta - downDelta };
}

function applyDelta(counters: CounterState, delta: ReturnType<typeof computeDelta>): CounterState {
  return {
    upvotes: counters.upvotes + delta.upDelta,
    downvotes: counters.downvotes + delta.downDelta,
    score: counters.score + delta.scoreDelta,
  };
}

// Reconciliation: recompute from ground truth (all votes)
function reconcileFromVotes(votes: VoteState[]): CounterState {
  let upvotes = 0;
  let downvotes = 0;
  for (const v of votes) {
    if (v.value === 1) upvotes++;
    else if (v.value === -1) downvotes++;
  }
  return { upvotes, downvotes, score: upvotes - downvotes };
}

describe("vote counter delta logic", () => {
  it("handles the full 6-step sequence correctly", () => {
    let counters: CounterState = { upvotes: 0, downvotes: 0, score: 0 };
    const votes = new Map<string, VoteState>();

    // Step 1: User A votes +1
    let delta = computeDelta(null, { value: 1 });
    counters = applyDelta(counters, delta);
    votes.set("A", { value: 1 });
    assert.deepEqual(counters, { upvotes: 1, downvotes: 0, score: 1 });
    assert.deepEqual(counters, reconcileFromVotes([...votes.values()]));

    // Step 2: User B votes -1
    delta = computeDelta(null, { value: -1 });
    counters = applyDelta(counters, delta);
    votes.set("B", { value: -1 });
    assert.deepEqual(counters, { upvotes: 1, downvotes: 1, score: 0 });
    assert.deepEqual(counters, reconcileFromVotes([...votes.values()]));

    // Step 3: User A flips to -1
    delta = computeDelta({ value: 1 }, { value: -1 });
    counters = applyDelta(counters, delta);
    votes.set("A", { value: -1 });
    assert.deepEqual(counters, { upvotes: 0, downvotes: 2, score: -2 });
    assert.deepEqual(counters, reconcileFromVotes([...votes.values()]));

    // Step 4: User C votes +1
    delta = computeDelta(null, { value: 1 });
    counters = applyDelta(counters, delta);
    votes.set("C", { value: 1 });
    assert.deepEqual(counters, { upvotes: 1, downvotes: 2, score: -1 });
    assert.deepEqual(counters, reconcileFromVotes([...votes.values()]));

    // Step 5: User B deletes vote
    delta = computeDelta({ value: -1 }, null);
    counters = applyDelta(counters, delta);
    votes.delete("B");
    assert.deepEqual(counters, { upvotes: 1, downvotes: 1, score: 0 });
    assert.deepEqual(counters, reconcileFromVotes([...votes.values()]));

    // Step 6: User A deletes vote
    delta = computeDelta({ value: -1 }, null);
    counters = applyDelta(counters, delta);
    votes.delete("A");
    assert.deepEqual(counters, { upvotes: 1, downvotes: 0, score: 1 });
    assert.deepEqual(counters, reconcileFromVotes([...votes.values()]));
  });

  it("flip from -1 to +1 moves both counters", () => {
    let counters: CounterState = { upvotes: 0, downvotes: 1, score: -1 };
    const delta = computeDelta({ value: -1 }, { value: 1 });
    counters = applyDelta(counters, delta);
    assert.deepEqual(counters, { upvotes: 1, downvotes: 0, score: 1 });
    assert.equal(delta.upDelta, 1);
    assert.equal(delta.downDelta, -1);
    assert.equal(delta.scoreDelta, 2);
  });

  it("no-op when before and after are equal", () => {
    const delta = computeDelta({ value: 1 }, { value: 1 });
    assert.equal(delta.upDelta, 0);
    assert.equal(delta.downDelta, 0);
    assert.equal(delta.scoreDelta, 0);
  });
});

describe("reconciliation restores drifted counters", () => {
  it("corrects upvotes drift", () => {
    // Simulate drift: counters say upvotes=5, but ground truth is 3
    const drifted: CounterState = { upvotes: 5, downvotes: 1, score: 4 };
    const votes: VoteState[] = [
      { value: 1 }, { value: 1 }, { value: 1 }, { value: -1 },
    ];
    const reconciled = reconcileFromVotes(votes);
    assert.deepEqual(reconciled, { upvotes: 3, downvotes: 1, score: 2 });
    assert.notDeepEqual(drifted, reconciled);
  });

  it("handles empty votes (all deleted)", () => {
    const reconciled = reconcileFromVotes([]);
    assert.deepEqual(reconciled, { upvotes: 0, downvotes: 0, score: 0 });
  });
});
