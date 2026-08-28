import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/services/creator_share.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PublicCreatorProfileScreen extends ConsumerStatefulWidget {
  final String creatorId;

  const PublicCreatorProfileScreen({super.key, required this.creatorId});

  @override
  ConsumerState<PublicCreatorProfileScreen> createState() =>
      _PublicCreatorProfileScreenState();
}

class _PublicCreatorProfileScreenState
    extends ConsumerState<PublicCreatorProfileScreen> {
  final _shareKey = GlobalKey();
  bool _following = false;
  bool _followBusy = false;
  bool _shareBusy = false;
  bool _blocked = false;
  int _followerDelta = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadFollowState);
  }

  Future<void> _loadFollowState() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || user.uid == widget.creatorId) return;
    try {
      final following = await ref
          .read(creatorFollowRepositoryProvider)
          .isFollowing(followerId: user.uid, followedId: widget.creatorId);
      if (mounted) setState(() => _following = following);
    } catch (_) {
      // Public identity remains readable when private follow state is offline.
    }
  }

  Future<void> _toggleFollow() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to follow this creator.')),
      );
      return;
    }
    if (user.uid == widget.creatorId || _followBusy) return;
    final before = _following;
    setState(() {
      _following = !before;
      _followerDelta += _following ? 1 : -1;
      _followBusy = true;
    });
    try {
      await ref
          .read(creatorFollowRepositoryProvider)
          .setFollowing(
            targetCreatorId: widget.creatorId,
            following: _following,
          );
      if (mounted) setState(() => _followBusy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _following = before;
        _followerDelta += before ? 1 : -1;
        _followBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this follow.')),
      );
    }
  }

  Future<void> _share(CreatorProfile creator) async {
    if (_shareBusy) return;
    final shareContext = _shareKey.currentContext;
    final renderObject = shareContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final origin = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    setState(() => _shareBusy = true);
    try {
      final destination = await ref
          .read(publicShareRepositoryProvider)
          .resolve(PublicShareTarget.creator, creator.id);
      if (!mounted) return;
      await ref
          .read(creatorShareGatewayProvider)
          .share(
            CreatorSharePayload.fromCreator(
              creator: creator,
              publicUrl: destination,
            ),
            sharePositionOrigin: origin,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This creator cannot be shared right now.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _shareBusy = false);
    }
  }

  Future<void> _block(CreatorProfile creator) async {
    final viewer = ref.read(authStateProvider).valueOrNull;
    if (viewer == null || viewer.uid == creator.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Block @${creator.handle}?'),
        content: const Text(
          'Their performances and comments will be hidden from your view. '
          'You can undo this from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('BLOCK'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(blockRepositoryProvider)
          .blockUser(
            blockerId: viewer.uid,
            blockedUserId: creator.id,
            blockedDisplayName: creator.displayName,
          );
      if (mounted) setState(() => _blocked = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not block this creator.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(creatorProfileProvider(widget.creatorId));
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final blockedUsers = viewer == null || viewer.uid == widget.creatorId
        ? const AsyncValue<Set<String>>.data(<String>{})
        : ref.watch(blockedUserIdsProvider(viewer.uid));
    final blocked =
        _blocked ||
        (blockedUsers.valueOrNull ?? const <String>{}).contains(
          widget.creatorId,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('CREATOR')),
      body: blockedUsers.isLoading
          ? const Center(child: CircularProgressIndicator())
          : blockedUsers.hasError
          ? _Unavailable(
              onRetry: () =>
                  ref.invalidate(blockedUserIdsProvider(viewer!.uid)),
            )
          : profile.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Unavailable(
                onRetry: () =>
                    ref.invalidate(creatorProfileProvider(widget.creatorId)),
              ),
              data: (creator) => blocked || creator == null || !creator.isPublic
                  ? _Unavailable(
                      onRetry: () => ref.invalidate(
                        creatorProfileProvider(widget.creatorId),
                      ),
                    )
                  : _body(creator),
            ),
    );
  }

  Widget _body(CreatorProfile creator) {
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final isSelf = viewer?.uid == creator.id;
    final followerCount = (creator.followerCount + _followerDelta).clamp(
      0,
      1 << 31,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxxl,
      ),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.chantLab,
            child: Text(
              creator.displayName.trim().isEmpty
                  ? '?'
                  : creator.displayName.trim()[0].toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          creator.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '@${creator.handle}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: AppColors.gold,
          ),
        ),
        if (creator.bio.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text(
            creator.bio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textBody),
          ),
        ],
        const SizedBox(height: Spacing.xl),
        Semantics(
          label:
              '$followerCount followers, ${creator.followingCount} following, ${creator.performanceCount} performances',
          child: Row(
            children: [
              _Stat(value: followerCount, label: 'FOLLOWERS'),
              _Stat(value: creator.followingCount, label: 'FOLLOWING'),
              _Stat(value: creator.performanceCount, label: 'PERFORMANCES'),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            if (!isSelf)
              Expanded(
                child: FilledButton(
                  onPressed: _followBusy ? null : _toggleFollow,
                  child: Text(_following ? 'FOLLOWING' : 'FOLLOW'),
                ),
              )
            else
              const Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  child: Text('THIS IS YOU'),
                ),
              ),
            const SizedBox(width: Spacing.sm),
            IconButton.outlined(
              key: _shareKey,
              tooltip: 'Share @${creator.handle}',
              onPressed: _shareBusy ? null : () => _share(creator),
              icon: const Icon(Icons.ios_share_outlined),
            ),
            if (!isSelf) ...[
              const SizedBox(width: Spacing.sm),
              IconButton.outlined(
                tooltip: 'Block @${creator.handle}',
                onPressed: () => _block(creator),
                icon: const Icon(Icons.block_outlined),
              ),
              const SizedBox(width: Spacing.sm),
              IconButton.outlined(
                tooltip: 'Report @${creator.handle}',
                onPressed: () => showReportSheet(
                  context: context,
                  target: ReportUser(creator.id),
                  ref: ref,
                ),
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ],
        ),
        const SizedBox(height: Spacing.xxl),
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Text(
            creator.performanceCount == 0
                ? 'No live performances yet.'
                : '${creator.performanceCount} live performance${creator.performanceCount == 1 ? '' : 's'} on Chant Stage.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text('$value', style: Theme.of(context).textTheme.titleLarge),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _Unavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: Spacing.md),
            const Text('This creator is not available.'),
            const SizedBox(height: Spacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}
