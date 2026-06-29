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
  void confirmWrite() {
    confirmedVote = userVote;
    optimisticDelta = 0;
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
      _vote.userVote = vote?.value;
      _vote.confirmedVote = vote?.value;
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
      if (e.toString().contains('PERMISSION_DENIED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account cannot vote right now. If you think this is wrong, use the suggestion box.',
            ),
          ),
        );
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
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: iconSize,
              ),
              color: _vote.userVote == 1 ? AppColors.gold : AppColors.textMuted,
              onPressed: () => _onVote(1),
              tooltip: 'Upvote',
              padding: EdgeInsets.zero,
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
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: iconSize,
              ),
              color: _vote.userVote == -1 ? AppColors.error : AppColors.textMuted,
              onPressed: () => _onVote(-1),
              tooltip: 'Downvote',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
