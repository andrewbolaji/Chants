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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHANT STAGE'),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where terrace ideas get a first voice.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: Spacing.lg),
                  _FeedFilters(selected: _filter, onSelected: _selectFilter),
                ],
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
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
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
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.xl,
              ),
              sliver: SliverList.separated(
                itemCount: _performances.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.xl),
                itemBuilder: (context, index) => PerformanceCard(
                  key: ValueKey<String>(
                    'performance-card-${_performances[index].id}',
                  ),
                  performance: _performances[index],
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
      label: 'Performance feed filter',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: ChoiceChip(
                  key: ValueKey<String>('stage-filter-${item.$1.name}'),
                  showCheckmark: false,
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected == item.$1
                        ? AppColors.goldOnDark
                        : AppColors.textMuted,
                  ),
                  label: SizedBox(
                    width: item.$1 == PerformanceFeedFilter.following ? 82 : 66,
                    child: Text(item.$2, textAlign: TextAlign.center),
                  ),
                  selected: selected == item.$1,
                  onSelected: (_) => onSelected(item.$1),
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
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          'Open @${performance.creatorHandle} creator profile',
                      child: InkWell(
                        onTap: _openCreator,
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.chantLab,
                              foregroundColor: AppColors.textHeadline,
                              child: Text(
                                performance.creatorDisplayName.trim().isEmpty
                                    ? '?'
                                    : performance.creatorDisplayName
                                          .trim()[0]
                                          .toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    performance.creatorDisplayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '@${performance.creatorHandle}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 10,
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
                  const SizedBox(width: Spacing.sm),
                  PopupMenuButton<String>(
                    tooltip: 'Performance actions',
                    onSelected: (value) {
                      if (value == 'report-performance') {
                        _reportPerformance();
                      } else if (value == 'report-creator') {
                        _reportCreator();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'report-performance',
                        child: Text('Report performance'),
                      ),
                      PopupMenuItem(
                        value: 'report-creator',
                        child: Text('Report creator'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.stageLeader && performance.weeklyUniqueSharerCount > 0)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.md,
                  0,
                  Spacing.md,
                  Spacing.md,
                ),
                child: _TrustPill(
                  label: '#1 MOST SHARED',
                  color: AppColors.chantLab,
                ),
              ),
            AspectRatio(aspectRatio: 4 / 5, child: media),
            Padding(
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
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (performance.caption.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      performance.caption,
                      style: const TextStyle(color: AppColors.textBody),
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
                  const SizedBox(height: Spacing.md),
                  TextButton.icon(
                    onPressed: _openLyrics,
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('OPEN CHANT & LYRICS'),
                  ),
                ],
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
