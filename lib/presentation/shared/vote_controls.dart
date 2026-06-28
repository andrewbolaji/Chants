import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';

class VoteControls extends ConsumerStatefulWidget {
  final Chant chant;
  final bool large;

  const VoteControls({super.key, required this.chant, this.large = false});

  @override
  ConsumerState<VoteControls> createState() => _VoteControlsState();
}

class _VoteControlsState extends ConsumerState<VoteControls> {
  int? _userVote;
  bool _loaded = false;
  bool _busy = false;

  // Optimistic score tracking. _serverScore is the last known server value;
  // _optimisticDelta is the local adjustment applied on tap and reverted on
  // error. On the next stream emission the server score replaces both.
  late int _serverScore;
  int _optimisticDelta = 0;

  @override
  void initState() {
    super.initState();
    _serverScore = widget.chant.score;
    _loadUserVote();
  }

  @override
  void didUpdateWidget(VoteControls old) {
    super.didUpdateWidget(old);
    // Reconcile to server score on stream emission.
    if (old.chant.score != widget.chant.score) {
      _serverScore = widget.chant.score;
      _optimisticDelta = 0;
    }
  }

  int get _displayScore => _serverScore + _optimisticDelta;

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
      _userVote = vote?.value;
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
    if (_busy) return;

    final previousVote = _userVote;
    final previousDelta = _optimisticDelta;

    // Calculate the correct optimistic delta swing.
    int deltaChange;
    int? newVote;
    if (_userVote == value) {
      // Toggle off: undo the current vote
      deltaChange = -value;
      newVote = null;
    } else if (_userVote != null) {
      // Switching direction: remove old + add new (net swing of 2)
      deltaChange = -_userVote! + value;
      newVote = value;
    } else {
      // Fresh vote
      deltaChange = value;
      newVote = value;
    }

    setState(() {
      _busy = true;
      _userVote = newVote;
      _optimisticDelta += deltaChange;
    });

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
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      // Revert optimistic state on failure
      setState(() {
        _userVote = previousVote;
        _optimisticDelta = previousDelta;
        _busy = false;
      });
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

    final score = _displayScore;
    final iconSize = widget.large ? 28.0 : 22.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upvote
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: iconSize,
              ),
              color: _userVote == 1 ? AppColors.gold : AppColors.textMuted,
              onPressed: _busy ? null : () => _onVote(1),
              tooltip: 'Upvote',
              padding: EdgeInsets.zero,
            ),
          ),

          // Score: Space Mono stamped number
          SizedBox(
            width: widget.large ? 48 : 36,
            child: Text(
              score.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: widget.large ? 16 : 13,
                color: score > 0
                    ? AppColors.textHeadline
                    : score < 0
                        ? AppColors.textMuted
                        : AppColors.textMuted,
              ),
            ),
          ),

          // Downvote
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: iconSize,
              ),
              color: _userVote == -1 ? AppColors.error : AppColors.textMuted,
              onPressed: _busy ? null : () => _onVote(-1),
              tooltip: 'Downvote',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
