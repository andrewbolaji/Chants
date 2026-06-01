import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserVote();
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
    setState(() => _busy = true);

    try {
      final voteRepo = ref.read(voteRepositoryProvider);
      if (_userVote == value) {
        await voteRepo.removeVote(
          userId: user.uid,
          chantId: widget.chant.id,
        );
        if (!mounted) return;
        setState(() {
          _userVote = null;
          _busy = false;
        });
      } else {
        await voteRepo.castVote(
          userId: user.uid,
          chantId: widget.chant.id,
          value: value,
        );
        if (!mounted) return;
        setState(() {
          _userVote = value;
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.toString().contains('PERMISSION_DENIED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your account cannot vote right now. If you think this is a mistake, use the suggestion box.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Width matches the rendered vote row (up + score + down). Retune or
    // replace with IntrinsicWidth if the row design changes.
    if (!_loaded) return const SizedBox(width: 88);

    final score = widget.chant.score;
    final iconSize = widget.large ? 28.0 : 22.0;
    final scoreStyle = widget.large
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: Icon(
              _userVote == 1
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_up_rounded,
              size: iconSize,
            ),
            color: _userVote == 1 ? AppColors.gold : AppColors.textMuted,
            onPressed: _busy ? null : () => _onVote(1),
            tooltip: 'Upvote',
          ),
        ),

        // Score
        SizedBox(
          width: widget.large ? 48 : 32,
          child: Text(
            score.toString(),
            textAlign: TextAlign.center,
            style: scoreStyle?.copyWith(
              fontWeight: FontWeight.w700,
              color: score > 0
                  ? AppColors.textPrimary
                  : score < 0
                      ? AppColors.textMuted
                      : AppColors.textMuted,
            ),
          ),
        ),

        // Downvote
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: iconSize,
            ),
            color: _userVote == -1 ? AppColors.error : AppColors.textMuted,
            onPressed: _busy ? null : () => _onVote(-1),
            tooltip: 'Downvote',
          ),
        ),
      ],
    );
  }
}
