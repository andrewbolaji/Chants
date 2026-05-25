import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/chant.dart';

class VoteControls extends ConsumerStatefulWidget {
  final Chant chant;

  const VoteControls({super.key, required this.chant});

  @override
  ConsumerState<VoteControls> createState() => _VoteControlsState();
}

class _VoteControlsState extends ConsumerState<VoteControls> {
  int? _userVote; // 1, -1, or null
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
        // Toggle off: remove the vote
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
        // Cast or flip
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
      final msg = e.toString();
      if (msg.contains('PERMISSION_DENIED')) {
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
    if (!_loaded) return const SizedBox(width: 80);

    final score = widget.chant.score;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toString(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            _userVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 20,
          ),
          color: _userVote == 1 ? theme.colorScheme.primary : null,
          visualDensity: VisualDensity.compact,
          onPressed: _busy ? null : () => _onVote(1),
          tooltip: 'Upvote',
        ),
        IconButton(
          icon: Icon(
            _userVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 20,
          ),
          color: _userVote == -1 ? theme.colorScheme.error : null,
          visualDensity: VisualDensity.compact,
          onPressed: _busy ? null : () => _onVote(-1),
          tooltip: 'Downvote',
        ),
      ],
    );
  }
}
