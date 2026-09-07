import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/performance.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/services/performance_share.dart';
import 'package:chants/presentation/feed/performance_video_player.dart';
import 'package:chants/presentation/feed/performance_comments_sheet.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PerformanceMediaBuilder =
    Widget Function(BuildContext context, Performance performance);

class ChantStageScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreate;
  final VoidCallback onBrowseClubs;
  final PerformanceMediaBuilder? mediaBuilder;

  const ChantStageScreen({
    super.key,
    required this.onCreate,
    required this.onBrowseClubs,
    this.mediaBuilder,
  });

  @override
  ConsumerState<ChantStageScreen> createState() => _ChantStageScreenState();
}

class _ChantStageScreenState extends ConsumerState<ChantStageScreen> {
  PerformanceFeedFilter _filter = PerformanceFeedFilter.rising;
  List<Performance> _performances = const [];
  Object? _cursor;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _followingFallback = false;
  List<String> _followingCreatorIds = const [];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_reload);
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _performances = const [];
      _cursor = null;
      _hasMore = false;
      _followingFallback = false;
      _followingCreatorIds = const [];
    });
    try {
      var fallback = false;
      var followingCreatorIds = const <String>[];
      late final PerformancePage page;
      if (_filter == PerformanceFeedFilter.following) {
        final user = ref.read(authStateProvider).valueOrNull;
        followingCreatorIds = user == null
            ? const []
            : await ref
                  .read(creatorFollowRepositoryProvider)
                  .followedCreatorIds(user.uid);
        if (followingCreatorIds.isEmpty) {
          fallback = true;
          page = await ref
              .read(performanceRepositoryProvider)
              .fetchPage(filter: PerformanceFeedFilter.rising);
        } else {
          page = await ref
              .read(performanceRepositoryProvider)
              .fetchFollowingPage(creatorIds: followingCreatorIds);
        }
      } else {
        page = await ref
            .read(performanceRepositoryProvider)
            .fetchPage(filter: _filter);
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _performances = page.performances;
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _followingFallback = fallback;
        _followingCreatorIds = followingCreatorIds;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page =
          _filter == PerformanceFeedFilter.following && !_followingFallback
          ? await ref
                .read(performanceRepositoryProvider)
                .fetchFollowingPage(
                  creatorIds: _followingCreatorIds,
                  cursor: _cursor,
                )
          : await ref
                .read(performanceRepositoryProvider)
                .fetchPage(
                  filter: _followingFallback
                      ? PerformanceFeedFilter.rising
                      : _filter,
                  cursor: _cursor,
                );
      if (!mounted || generation != _generation) return;
      setState(() {
        final seen = _performances.map((item) => item.id).toSet();
        _performances = List.unmodifiable([
          ..._performances,
          ...page.performances.where((item) => seen.add(item.id)),
        ]);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loadingMore = false;
      });
    }
  }

  void _selectFilter(PerformanceFeedFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final blockedUsers = viewer == null
        ? const AsyncValue<Set<String>>.data(<String>{})
        : ref.watch(blockedUserIdsProvider(viewer.uid));
    final visiblePerformances = _performances
        .where(
          (performance) => !(blockedUsers.valueOrNull ?? const <String>{})
              .contains(performance.creatorId),
        )
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.stageChrome,
        toolbarHeight: 68,
        titleSpacing: Spacing.lg,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CHANTS FC',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.gold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'CHANT STAGE',
              style: TextStyle(
                fontFamily: 'Anton',
                fontSize: 24,
                height: 1,
                letterSpacing: 0.3,
                color: AppColors.textHeadline,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Activity',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.creatorNotifications),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: CustomScrollView(
        key: PageStorageKey<String>('chant-stage-${_filter.name}'),
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.stageChrome,
                border: Border(
                  bottom: BorderSide(color: AppColors.stageRule, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  0,
                  Spacing.sm,
                ),
                child: _FeedFilters(
                  selected: _filter,
                  onSelected: _selectFilter,
                ),
              ),
            ),
          ),
          if (_followingFallback && !_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: const _FollowingDiscoveryNotice(),
              ),
            ),
          if (_loading || blockedUsers.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (blockedUsers.hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StageUnavailable(
                onRetry: () =>
                    ref.invalidate(blockedUserIdsProvider(viewer!.uid)),
              ),
            )
          else if (_error != null && _performances.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StageUnavailable(onRetry: _reload),
            )
          else if (_performances.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyStage(
                onCreate: widget.onCreate,
                onBrowseClubs: widget.onBrowseClubs,
              ),
            )
          else if (visiblePerformances.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _BlockedStage(
                canLoadMore: _hasMore,
                onLoadMore: _loadMore,
                onBrowseClubs: widget.onBrowseClubs,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, Spacing.xl),
              sliver: SliverList.separated(
                itemCount: visiblePerformances.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
                itemBuilder: (context, index) => PerformanceCard(
                  key: ValueKey<String>(
                    'performance-card-${visiblePerformances[index].id}',
                  ),
                  performance: visiblePerformances[index],
                  stageLeader:
                      _filter == PerformanceFeedFilter.rising && index == 0,
                  mediaBuilder: widget.mediaBuilder,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.xxxl,
                ),
                child: _loadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : _hasMore
                    ? OutlinedButton(
                        onPressed: _loadMore,
                        child: const Text('LOAD MORE'),
                      )
                    : const Center(
                        child: Text(
                          'YOU HAVE REACHED THE END',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedFilters extends StatelessWidget {
  final PerformanceFeedFilter selected;
  final ValueChanged<PerformanceFeedFilter> onSelected;

  const _FeedFilters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = [
      (PerformanceFeedFilter.rising, 'RISING'),
      (PerformanceFeedFilter.newest, 'NEW'),
      (PerformanceFeedFilter.terrace, 'TERRACE'),
      (PerformanceFeedFilter.following, 'FOLLOWING'),
    ];
    return Semantics(
      label: 'Performance Stage filter',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items)
              Semantics(
                selected: selected == item.$1,
                button: true,
                child: InkWell(
                  key: ValueKey<String>('stage-filter-${item.$1.name}'),
                  onTap: () => onSelected(item.$1),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: item.$1 == PerformanceFeedFilter.following
                          ? 104
                          : 78,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected == item.$1
                              ? AppColors.gold
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: selected == item.$1
                            ? AppColors.textHeadline
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowingDiscoveryNotice extends StatelessWidget {
  const _FollowingDiscoveryNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey<String>('following-discovery-notice'),
      label:
          'Following feed has no creators yet. Showing Rising performances for discovery.',
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.chantLab.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: AppColors.chantLab),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.people_outline, color: AppColors.chantLab),
            SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'FOLLOWING STARTS HERE\nShowing Rising performances until you follow a creator.',
                style: TextStyle(color: AppColors.textBody),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedStage extends StatelessWidget {
  final bool canLoadMore;
  final VoidCallback onLoadMore;
  final VoidCallback onBrowseClubs;

  const _BlockedStage({
    required this.canLoadMore,
    required this.onLoadMore,
    required this.onBrowseClubs,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_off_outlined, size: 42),
            const SizedBox(height: Spacing.md),
            Text(
              'NO UNBLOCKED PERFORMANCES HERE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            const Text(
              'Creators you block stay out of your Stage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: Spacing.lg),
            if (canLoadMore)
              FilledButton(
                onPressed: onLoadMore,
                child: const Text('LOAD MORE'),
              )
            else
              OutlinedButton(
                onPressed: onBrowseClubs,
                child: const Text('BROWSE CLUBS'),
              ),
          ],
        ),
      ),
    );
  }
}

class PerformanceCard extends ConsumerStatefulWidget {
  final Performance performance;
  final bool stageLeader;
  final PerformanceMediaBuilder? mediaBuilder;

  const PerformanceCard({
    super.key,
    required this.performance,
    this.stageLeader = false,
    this.mediaBuilder,
  });

  @override
  ConsumerState<PerformanceCard> createState() => _PerformanceCardState();
}

class _PerformanceCardState extends ConsumerState<PerformanceCard> {
  late Performance _performance;
  bool _liked = false;
  bool _likeBusy = false;
  bool _shareBusy = false;
  int _likeGeneration = 0;
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _performance = widget.performance;
    Future<void>.microtask(_loadLike);
  }

  @override
  void didUpdateWidget(PerformanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.performance.id != widget.performance.id) {
      _performance = widget.performance;
      _liked = false;
      _likeBusy = false;
      _shareBusy = false;
      Future<void>.microtask(_loadLike);
    } else {
      _performance = widget.performance.copyWith(
        likeCount: _liked && widget.performance.likeCount == 0
            ? _performance.likeCount
            : widget.performance.likeCount,
      );
    }
  }

  Future<void> _loadLike() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final generation = ++_likeGeneration;
    try {
      final liked = await ref
          .read(performanceInteractionRepositoryProvider)
          .isLiked(userId: user.uid, performanceId: _performance.id);
      if (!mounted || generation != _likeGeneration) return;
      setState(() => _liked = liked);
    } catch (_) {
      // The feed stays usable when private like state is temporarily offline.
    }
  }

  Future<void> _toggleLike() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || _likeBusy) return;
    final beforeLiked = _liked;
    final beforePerformance = _performance;
    final nextLiked = !beforeLiked;
    setState(() {
      _likeBusy = true;
      _liked = nextLiked;
      _performance = _performance.copyWith(
        likeCount: (_performance.likeCount + (nextLiked ? 1 : -1)).clamp(
          0,
          1 << 31,
        ),
      );
    });
    try {
      await ref
          .read(performanceInteractionRepositoryProvider)
          .setLiked(performanceId: _performance.id, liked: nextLiked);
      if (!mounted) return;
      setState(() => _likeBusy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = beforeLiked;
        _performance = beforePerformance;
        _likeBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this like.')),
      );
    }
  }

  Future<void> _recordQualifiedView() async {
    await ref
        .read(performanceInteractionRepositoryProvider)
        .recordQualifiedView(_performance.id);
  }

  Future<void> _openComments() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PerformanceCommentsSheet(
        performanceId: _performance.id,
        chantTitle: _performance.chantTitle,
      ),
    );
  }

  Future<void> _share() async {
    if (_shareBusy) return;
    final shareContext = _shareKey.currentContext;
    final renderObject = shareContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final origin = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    setState(() => _shareBusy = true);
    var handedOff = false;
    try {
      final destination = await ref
          .read(publicShareRepositoryProvider)
          .resolve(PublicShareTarget.performance, _performance.id);
      if (!mounted) return;
      handedOff = await ref
          .read(performanceShareGatewayProvider)
          .share(
            PerformanceSharePayload.fromPerformance(
              performance: _performance,
              publicUrl: destination,
            ),
            sharePositionOrigin: origin,
          );
      if (!handedOff || !mounted) return;
      final counted = await ref
          .read(performanceInteractionRepositoryProvider)
          .recordShare(_performance.id);
      if (!mounted) return;
      if (counted) {
        final userId = ref.read(authStateProvider).valueOrNull?.uid;
        final rankingEligible =
            userId != null && userId != _performance.creatorId;
        setState(() {
          _performance = _performance.copyWith(
            shareCount: _performance.shareCount + 1,
            uniqueSharerCount: _performance.uniqueSharerCount + 1,
            weeklyUniqueSharerCount: rankingEligible
                ? _performance.weeklyUniqueSharerCount + 1
                : _performance.weeklyUniqueSharerCount,
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            handedOff
                ? 'Shared, but the reach count could not be updated.'
                : 'This performance cannot be shared right now.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _shareBusy = false);
    }
  }

  Future<void> _openLyrics() async {
    try {
      final chant = await ref
          .read(chantRepositoryProvider)
          .getChant(_performance.chantId);
      if (!mounted) return;
      if (chant == null || chant.hidden || chant.removed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This chant is not available.')),
        );
        return;
      }
      await Navigator.pushNamed(
        context,
        AppRouter.chantDetail,
        arguments: ChantDetailRouteArguments(chant: chant),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open lyrics. Try again.')),
      );
    }
  }

  Future<void> _openCreator() async {
    await Navigator.pushNamed(
      context,
      AppRouter.creatorProfile,
      arguments: _performance.creatorId,
    );
  }

  Future<void> _blockCreator() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || user.uid == _performance.creatorId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Block @${_performance.creatorHandle}?'),
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
            blockerId: user.uid,
            blockedUserId: _performance.creatorId,
            blockedDisplayName: _performance.creatorDisplayName,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not block this creator.')),
      );
    }
  }

  void _reportPerformance() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to report this performance.')),
      );
      return;
    }
    showReportSheet(
      context: context,
      target: ReportPerformance(_performance.id),
      ref: ref,
    );
  }

  void _reportCreator() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to report this creator.')),
      );
      return;
    }
    showReportSheet(
      context: context,
      target: ReportUser(_performance.creatorId),
      ref: ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    final performance = _performance;
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final subject = performance.playerName ?? performance.teamName;
    final media =
        widget.mediaBuilder?.call(context, performance) ??
        _DefaultPerformanceMedia(
          performance: performance,
          onQualifiedView: _recordQualifiedView,
        );
    return Semantics(
      container: true,
      label:
          '${performance.creatorDisplayName} performs ${performance.chantTitle} for $subject',
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.stagePanel,
                border: Border(
                  top: BorderSide(color: AppColors.stageRule, width: 0.5),
                  bottom: BorderSide(color: AppColors.stageRule, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.sm,
                  Spacing.sm,
                  Spacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label:
                            'Open @${performance.creatorHandle} creator profile',
                        child: InkWell(
                          onTap: _openCreator,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceRaised,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    performance.creatorDisplayName
                                            .trim()
                                            .isEmpty
                                        ? '?'
                                        : performance.creatorDisplayName
                                              .trim()[0]
                                              .toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textHeadline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        performance.creatorDisplayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textHeadline,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '@${performance.creatorHandle}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'SpaceMono',
                                          fontSize: 9,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    PopupMenuButton<String>(
                      tooltip: 'Performance actions',
                      onSelected: (value) {
                        if (value == 'block-creator') {
                          _blockCreator();
                        } else if (value == 'report-performance') {
                          _reportPerformance();
                        } else if (value == 'report-creator') {
                          _reportCreator();
                        }
                      },
                      itemBuilder: (_) => [
                        if (viewer != null &&
                            viewer.uid != performance.creatorId)
                          const PopupMenuItem(
                            value: 'block-creator',
                            child: Text('Block creator'),
                          ),
                        const PopupMenuItem(
                          value: 'report-performance',
                          child: Text('Report performance'),
                        ),
                        const PopupMenuItem(
                          value: 'report-creator',
                          child: Text('Report creator'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Stack(
              children: [
                AspectRatio(aspectRatio: 4 / 5, child: media),
                if (widget.stageLeader &&
                    performance.weeklyUniqueSharerCount > 0)
                  const Positioned(
                    left: Spacing.lg,
                    top: Spacing.lg,
                    child: _BroadcastLabel(
                      text: '#1 MOST SHARED',
                      icon: Icons.trending_up,
                    ),
                  ),
              ],
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.stagePanel,
                border: Border(
                  top: BorderSide(color: AppColors.stageRule, width: 0.5),
                  bottom: BorderSide(color: AppColors.stageRule, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        _TrustPill(
                          label: performance.isTerraceProven
                              ? 'TERRACE PROVEN'
                              : 'CHANT LAB',
                          color: performance.isTerraceProven
                              ? AppColors.gold
                              : AppColors.chantLab,
                        ),
                        _TrustPill(
                          label: performance.playerName == null
                              ? performance.teamName.toUpperCase()
                              : performance.playerName!.toUpperCase(),
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      performance.chantTitle.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 30,
                        height: 0.98,
                        letterSpacing: 0.2,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    if (performance.caption.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        performance.caption,
                        style: const TextStyle(
                          color: AppColors.textBody,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.lg),
                    _PerformanceMetrics(
                      performance: performance,
                      liked: _liked,
                      likeBusy: _likeBusy,
                      onLike: _toggleLike,
                      onComments: _openComments,
                      shareKey: _shareKey,
                      shareBusy: _shareBusy,
                      onShare: _share,
                    ),
                    const SizedBox(height: Spacing.sm),
                    const Divider(color: AppColors.stageRule),
                    TextButton.icon(
                      onPressed: _openLyrics,
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('OPEN CHANT & LYRICS'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _BroadcastLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.stageScrim,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.smMd,
          vertical: Spacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.gold),
            const SizedBox(width: Spacing.xs),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textHeadline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultPerformanceMedia extends ConsumerWidget {
  final Performance performance;
  final Future<void> Function() onQualifiedView;

  const _DefaultPerformanceMedia({
    required this.performance,
    required this.onQualifiedView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PerformanceVideoPlayer(
      resolveMediaUri: () => ref
          .read(performanceRepositoryProvider)
          .resolvePlayback(performance.id),
      onQualifiedView: onQualifiedView,
      semanticLabel:
          'Play ${performance.chantTitle} by ${performance.creatorDisplayName}',
    );
  }
}

class _PerformanceMetrics extends StatelessWidget {
  final Performance performance;
  final bool liked;
  final bool likeBusy;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final GlobalKey shareKey;
  final bool shareBusy;
  final VoidCallback onShare;

  const _PerformanceMetrics({
    required this.performance,
    required this.liked,
    required this.likeBusy,
    required this.onLike,
    required this.onComments,
    required this.shareKey,
    required this.shareBusy,
    required this.onShare,
  });

  String _compact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>('performance-metrics-${performance.id}'),
      label:
          '${performance.viewCount} views, ${performance.likeCount} likes, ${performance.commentCount} comments, ${performance.shareCount} unique sharers',
      child: Row(
        children: [
          Expanded(
            child: _MetricAction(
              icon: Icons.play_circle_outline,
              count: _compact(performance.viewCount),
              semanticLabel: '${performance.viewCount} qualified views',
            ),
          ),
          Expanded(
            child: _MetricAction(
              key: ValueKey<String>('performance-like-${performance.id}'),
              icon: liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? AppColors.error : AppColors.textMuted,
              count: _compact(performance.likeCount),
              semanticLabel: liked
                  ? 'Unlike performance, ${performance.likeCount} likes'
                  : 'Like performance, ${performance.likeCount} likes',
              onTap: likeBusy ? null : onLike,
            ),
          ),
          Expanded(
            child: _MetricAction(
              key: ValueKey<String>('performance-comments-${performance.id}'),
              icon: Icons.chat_bubble_outline,
              count: _compact(performance.commentCount),
              semanticLabel:
                  'Open ${performance.commentCount} performance comments',
              onTap: onComments,
            ),
          ),
          Expanded(
            child: _MetricAction(
              key: shareKey,
              icon: Icons.ios_share_outlined,
              count: _compact(performance.shareCount),
              semanticLabel:
                  'Share performance, '
                  '${performance.shareCount} unique sharers',
              onTap: shareBusy ? null : onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricAction extends StatelessWidget {
  final IconData icon;
  final String count;
  final String semanticLabel;
  final Color color;
  final VoidCallback? onTap;

  const _MetricAction({
    super.key,
    required this.icon,
    required this.count,
    required this.semanticLabel,
    this.color = AppColors.textMuted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: Spacing.xs),
                Text(
                  count,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TrustPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyStage extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onBrowseClubs;

  const _EmptyStage({required this.onCreate, required this.onBrowseClubs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.chantLab,
            ),
            const SizedBox(height: Spacing.lg),
            const SectionEyebrow(text: 'The stage is yours', gold: true),
            const SizedBox(height: Spacing.sm),
            const Text(
              'No approved performances are here yet. Start with a chant idea '
              'or find the one you want to give a voice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: onCreate,
              child: const Text('START A CHANT'),
            ),
            TextButton(
              onPressed: onBrowseClubs,
              child: const Text('BROWSE CLUBS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageUnavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _StageUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The Chant Stage could not be loaded.'),
            const SizedBox(height: Spacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}
