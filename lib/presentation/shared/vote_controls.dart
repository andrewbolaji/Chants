import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';

/// Encapsulates the optimistic vote reconciliation logic.
/// The widget delegates all score math here so it can be tested directly.
class OptimisticVoteState {
  int serverScore;
  int? userVote;
  int? confirmedVote;
  int optimisticDelta = 0;
  bool busy = false;

  OptimisticVoteState({required this.serverScore, this.userVote, this.confirmedVote});

  int get displayScore => serverScore + optimisticDelta;

  /// Pure delta for a vote transition: previous -> next.
  static int deltaForTransition(int? from, int? to) {
    return (to ?? 0) - (from ?? 0);
  }

  /// Called when the user taps a vote button. Returns the new vote value
  /// (null = removed) and updates internal state optimistically.
  int? applyVote(int value) {
    final int? newVote = (userVote == value) ? null : value;
    optimisticDelta = deltaForTransition(confirmedVote, newVote);
    userVote = newVote;
    busy = true;
    return newVote;
  }

  /// Called when the async write succeeds.
  /// Only clears busy. The delta and confirmedVote stay until the server
  /// score stream arrives, because the Cloud Function that updates score
  /// runs after the local write completes.
  void confirmWrite() {
    busy = false;
  }

  /// Called when the async write fails. Reverts to previous state.
  void revertWrite(int? previousVote, int? previousConfirmed) {
    userVote = previousVote;
    confirmedVote = previousConfirmed;
    optimisticDelta = deltaForTransition(confirmedVote, userVote);
    busy = false;
  }

  /// Called when a new server score arrives (e.g. from Firestore stream).
  void reconcileServerScore(int newServerScore) {
    if (newServerScore == serverScore) return;
    serverScore = newServerScore;
    if (!busy) {
      confirmedVote = userVote;
      optimisticDelta = 0;
    } else {
      optimisticDelta = deltaForTransition(confirmedVote, userVote);
    }
  }
}

class VoteControls extends ConsumerStatefulWidget {
  final Chant chant;
  final bool large;
  final bool compact;

  const VoteControls({
    super.key,
    required this.chant,
    this.large = false,
    this.compact = false,
  });

  @override
  ConsumerState<VoteControls> createState() => _VoteControlsState();
}

class _VoteControlsState extends ConsumerState<VoteControls> {
  bool _loaded = false;
  late final OptimisticVoteState _vote;
  bool _hasPendingChange = false;

  @override
  void initState() {
    super.initState();
    _vote = OptimisticVoteState(serverScore: widget.chant.score);
    _loadUserVote();
  }

  @override
  void didUpdateWidget(VoteControls old) {
    super.didUpdateWidget(old);
    if (old.chant.score != widget.chant.score) {
      _vote.reconcileServerScore(widget.chant.score);
    }
  }

  Future<void> _loadUserVote() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _loaded = true);
      return;
    }
    final vote = await ref.read(voteRepositoryProvider).getUserVote(
          userId: user.uid,
          chantId: widget.chant.id,
        );
    if (!mounted) return;
    setState(() {
      if (vote != null) {
        _vote.userVote = vote.value;
        if (vote.appliedValue == vote.value) {
          // Case A: CF has processed this exact vote. Score includes it.
          _vote.confirmedVote = vote.value;
        } else {
          // Case B: CF has not processed this vote yet, or processed an
          // older value (flip). confirmedVote = what the server already
          // reflects (null for a new vote, old value for a flip).
          _vote.confirmedVote = vote.appliedValue;
          _vote.optimisticDelta = OptimisticVoteState.deltaForTransition(
            vote.appliedValue, vote.value,
          );
        }
      }
      _loaded = true;
    });
  }

  Future<void> _onVote(int value) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to vote.')),
      );
      return;
    }

    // In-flight guard: if a write is pending, record that the user changed
    // their mind. applyVote updates userVote and optimisticDelta immediately
    // so the UI never looks frozen, but only one Firestore write is in flight
    // at a time. After the current write completes, the follow-up writes the
    // settled intent (userVote) directly, without re-calling applyVote.
    if (_vote.busy) {
      _hasPendingChange = true;
      _vote.applyVote(value);
      setState(() {});
      return;
    }

    final previousVote = _vote.userVote;
    final previousConfirmed = _vote.confirmedVote;

    final newVote = _vote.applyVote(value);
    setState(() {});

    try {
      final voteRepo = ref.read(voteRepositoryProvider);
      if (newVote == null) {
        await voteRepo.removeVote(
          userId: user.uid,
          chantId: widget.chant.id,
        );
      } else {
        await voteRepo.castVote(
          userId: user.uid,
          chantId: widget.chant.id,
          value: newVote,
        );
      }
      if (!mounted) return;
      setState(() => _vote.confirmWrite());
    } catch (e) {
      if (!mounted) return;
      setState(() => _vote.revertWrite(previousVote, previousConfirmed));
      _hasPendingChange = false;
      if (e.toString().contains('PERMISSION_DENIED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account cannot vote right now. If you think this is wrong, use the suggestion box.',
            ),
          ),
        );
      }
      return;
    }

    // Follow-up: if the user changed their mind while the write was in
    // flight, write the settled intent (userVote) directly. This avoids the
    // old bug where replaying the raw tap value through applyVote re-toggled
    // the intent, causing drift.
    if (_hasPendingChange) {
      _hasPendingChange = false;
      final settledVote = _vote.userVote;
      if (settledVote != newVote) {
        await _writeSettledIntent(user.uid, settledVote, newVote);
      }
    }
  }

  /// Writes the user's settled intent directly, without calling applyVote.
  /// The optimistic state (userVote, optimisticDelta) is already correct
  /// from the busy-guard applyVote calls. This only syncs Firestore.
  Future<void> _writeSettledIntent(
    String userId,
    int? settledVote,
    int? fallbackVote,
  ) async {
    _vote.busy = true;
    setState(() {});

    try {
      final voteRepo = ref.read(voteRepositoryProvider);
      if (settledVote == null) {
        await voteRepo.removeVote(
          userId: userId,
          chantId: widget.chant.id,
        );
      } else {
        await voteRepo.castVote(
          userId: userId,
          chantId: widget.chant.id,
          value: settledVote,
        );
      }
      if (!mounted) return;
      setState(() => _vote.confirmWrite());
    } catch (e) {
      if (!mounted) return;
      setState(() => _vote.revertWrite(fallbackVote, _vote.confirmedVote));
      _hasPendingChange = false;
      return;
    }

    // Handle further taps during this follow-up write
    if (_hasPendingChange) {
      _hasPendingChange = false;
      final furtherSettled = _vote.userVote;
      if (furtherSettled != settledVote) {
        await _writeSettledIntent(userId, furtherSettled, settledVote);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(width: 88);

    final score = _vote.displayScore;
    final iconSize = widget.large ? 28.0 : (widget.compact ? 18.0 : 22.0);
    final buttonSize = 44.0; // minimum tap target, always 44px
    final scoreWidth = widget.large ? 48.0 : (widget.compact ? 34.0 : 36.0);
    final fontSize = widget.large ? 16.0 : (widget.compact ? 12.0 : 13.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 0 : 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upvote
          Semantics(
            label: 'Upvote',
            button: true,
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_drop_up,
                  size: iconSize + 6,
                ),
                color: _vote.userVote == 1 ? AppColors.gold : AppColors.textMuted,
                onPressed: () => _onVote(1),
                tooltip: 'Upvote',
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Score: Space Mono stamped number
          SizedBox(
            width: scoreWidth,
            child: Text(
              score.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                color: score > 0
                    ? AppColors.textHeadline
                    : AppColors.textMuted,
              ),
            ),
          ),

          // Downvote
          Semantics(
            label: 'Downvote',
            button: true,
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: iconSize + 6,
                ),
                color: _vote.userVote == -1 ? AppColors.error : AppColors.textMuted,
                onPressed: () => _onVote(-1),
                tooltip: 'Downvote',
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
