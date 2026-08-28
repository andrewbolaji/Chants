import 'package:firebase_auth/firebase_auth.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/performance.dart';
import 'package:chants/data/models/performance_comment.dart';
import 'package:chants/data/repositories/performance_interaction_repository.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/data/repositories/creator_follow_repository.dart';
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/services/performance_share.dart';
import 'package:chants/presentation/feed/chant_stage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'fan-1';
}

PerformanceInteractionRepository _interactionRepository({
  PerformanceLikeAction? likeAction,
  PerformanceShareAction? shareAction,
  PerformanceCommentLoader? commentLoader,
}) {
  return PerformanceInteractionRepository(
    likeAction: likeAction ?? (_, _) async {},
    viewAction: (_) async {},
    shareAction: shareAction ?? (_) async => false,
    likeLoader: (_, _) async => false,
    commentLoader:
        commentLoader ?? (_) => Stream.value(const <PerformanceComment>[]),
    commentAction: (_, _, _, _) async => 'comment-1',
    commentDeleteAction: (_) async {},
  );
}

class _ShareGateway implements PerformanceShareGateway {
  int calls = 0;
  PerformanceSharePayload? payload;

  @override
  Future<bool> share(
    PerformanceSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {
    calls += 1;
    this.payload = payload;
    return true;
  }
}

Performance _performance({
  String id = 'performance-1',
  String chantStatus = 'community',
  int weeklyShares = 4,
}) {
  final now = DateTime.utc(2026, 8, 27);
  return Performance(
    id: id,
    chantId: 'chant-$id',
    chantTitle: 'Super Saka Every Week',
    teamId: 'arsenal',
    teamName: 'Arsenal',
    playerName: 'Bukayo Saka',
    chantStatus: chantStatus,
    creatorId: 'creator-1',
    creatorHandle: 'northbankleo',
    creatorDisplayName: 'North Bank Leo',
    caption: 'If this catches on, I am taking full credit.',
    mediaPath: 'performance-media/$id/source',
    durationMs: 18000,
    publicationState: PerformancePublicationState.approved,
    rankingWeek: '2026-08-24',
    viewCount: 1284,
    likeCount: 214,
    commentCount: 31,
    shareCount: 48,
    uniqueSharerCount: 42,
    weeklyUniqueSharerCount: weeklyShares,
    weeklyLikeCount: 80,
    weeklyQualifiedViewCount: 300,
    createdAt: now,
    approvedAt: now,
    updatedAt: now,
  );
}

Widget _app({
  required PerformanceRepository repository,
  PerformanceInteractionRepository? interactionRepository,
  User? user,
  PublicShareRepository? publicShareRepository,
  PerformanceShareGateway? performanceShareGateway,
  CreatorFollowRepository? followRepository,
  VoidCallback? onCreate,
  VoidCallback? onBrowseClubs,
}) {
  return ProviderScope(
    overrides: [
      performanceRepositoryProvider.overrideWithValue(repository),
      creatorFollowRepositoryProvider.overrideWithValue(
        followRepository ??
            CreatorFollowRepository(
              followedCreatorLoader: (_) async => const [],
              followStateLoader: (_, _) async => false,
              followAction: (_, _) async => false,
            ),
      ),
      performanceInteractionRepositoryProvider.overrideWithValue(
        interactionRepository ?? _interactionRepository(),
      ),
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      publicShareRepositoryProvider.overrideWithValue(
        publicShareRepository ??
            PublicShareRepository(
              resolver: (_, id) async =>
                  Uri.parse('https://chantsfc.com/performances/$id'),
            ),
      ),
      performanceShareGatewayProvider.overrideWithValue(
        performanceShareGateway ?? _ShareGateway(),
      ),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: ChantStageScreen(
        onCreate: onCreate ?? () {},
        onBrowseClubs: onBrowseClubs ?? () {},
        mediaBuilder: (_, _) => const ColoredBox(
          color: Color(0xFF59352F),
          child: Center(child: Icon(Icons.graphic_eq, size: 72)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Rising presents a real most-shared leader and honest trust', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = PerformanceRepository(
      pageLoader: (filter, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('CHANT STAGE'), findsOneWidget);
    expect(find.text('#1 MOST SHARED'), findsOneWidget);
    expect(find.text('CHANT LAB'), findsOneWidget);
    expect(find.text('TERRACE PROVEN'), findsNothing);
    expect(find.text('SUPER SAKA EVERY WEEK'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('performance-metrics-performance-1')),
          )
          .label,
      contains('1284 views, 214 likes, 31 comments, 48 unique sharers'),
    );
  });

  testWidgets('winner copy is withheld when no one shared this week', (
    tester,
  ) async {
    final repository = PerformanceRepository(
      pageLoader: (_, _) async => PerformancePage(
        performances: [_performance(weeklyShares: 0)],
        hasMore: false,
      ),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('#1 MOST SHARED'), findsNothing);
  });

  testWidgets('like intent is optimistic and server-authoritative', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final calls = <(String, bool)>[];
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
    );

    await tester.pumpWidget(
      _app(
        repository: repository,
        user: _User(),
        interactionRepository: _interactionRepository(
          likeAction: (performanceId, liked) async {
            calls.add((performanceId, liked));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('performance-like-performance-1')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('performance-like-performance-1')),
    );
    await tester.pumpAndSettle();

    expect(calls, [('performance-1', true)]);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('performance-like-performance-1')),
          )
          .label,
      contains('Unlike performance, 215 likes'),
    );
  });

  testWidgets('comment action opens the bounded conversation sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
    );

    await tester.pumpWidget(
      _app(
        repository: repository,
        user: _User(),
        interactionRepository: _interactionRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('performance-comments-performance-1')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('performance-comments-performance-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMMENTS'), findsOneWidget);
    expect(
      find.text('No comments yet. Be the first voice in the stand.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Post comment'), findsOneWidget);
  });

  testWidgets('share resolves the live URL before recording one unique reach', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final calls = <String>[];
    final gateway = _ShareGateway();
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
    );

    await tester.pumpWidget(
      _app(
        repository: repository,
        user: _User(),
        performanceShareGateway: gateway,
        publicShareRepository: PublicShareRepository(
          resolver: (target, id) async {
            calls.add('${target.name}:$id');
            return Uri.parse('https://chantsfc.com/performances/$id');
          },
        ),
        interactionRepository: _interactionRepository(
          shareAction: (performanceId) async {
            calls.add('count:$performanceId');
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Share performance, 48 unique sharers'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.bySemanticsLabel('Share performance, 48 unique sharers'),
    );
    await tester.pumpAndSettle();

    expect(calls, ['performance:performance-1', 'count:performance-1']);
    expect(gateway.calls, 1);
    expect(
      gateway.payload?.text,
      contains('https://chantsfc.com/performances/performance-1'),
    );
    expect(
      find.bySemanticsLabel('Share performance, 49 unique sharers'),
      findsOneWidget,
    );
  });

  testWidgets('New and Terrace filters reload through their real query mode', (
    tester,
  ) async {
    final calls = <PerformanceFeedFilter>[];
    final repository = PerformanceRepository(
      pageLoader: (filter, _) async {
        calls.add(filter);
        return PerformancePage(
          performances: [
            _performance(
              id: filter.name,
              chantStatus: filter == PerformanceFeedFilter.terrace
                  ? 'canonical'
                  : 'community',
            ),
          ],
          hasMore: false,
        );
      },
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stage-filter-newest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stage-filter-terrace')));
    await tester.pumpAndSettle();

    expect(calls, [
      PerformanceFeedFilter.rising,
      PerformanceFeedFilter.newest,
      PerformanceFeedFilter.terrace,
    ]);
    expect(find.text('TERRACE PROVEN'), findsOneWidget);
  });

  testWidgets('Following uses followed creators as a real feed signal', (
    tester,
  ) async {
    final followingCalls = <List<String>>[];
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
      followingPageLoader: (creatorIds, _) async {
        followingCalls.add(creatorIds);
        return PerformancePage(
          performances: [_performance(id: 'followed')],
          hasMore: false,
        );
      },
    );

    await tester.pumpWidget(
      _app(
        repository: repository,
        user: _User(),
        followRepository: CreatorFollowRepository(
          followedCreatorLoader: (_) async => const ['creator-1'],
          followStateLoader: (_, _) async => false,
          followAction: (_, _) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stage-filter-following')));
    await tester.pumpAndSettle();

    expect(followingCalls, [
      const ['creator-1'],
    ]);
    expect(find.text('FOLLOWING STARTS HERE'), findsNothing);
    expect(
      find.byKey(const ValueKey('performance-card-followed')),
      findsOneWidget,
    );
  });

  testWidgets('empty Following stays useful with an honest Rising fallback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final calls = <PerformanceFeedFilter>[];
    final repository = PerformanceRepository(
      pageLoader: (filter, _) async {
        calls.add(filter);
        return PerformancePage(
          performances: [_performance(id: filter.name)],
          hasMore: false,
        );
      },
    );

    await tester.pumpWidget(_app(repository: repository, user: _User()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stage-filter-following')));
    await tester.pumpAndSettle();

    expect(calls, [PerformanceFeedFilter.rising, PerformanceFeedFilter.rising]);
    expect(find.textContaining('FOLLOWING STARTS HERE'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('following-discovery-notice')),
          )
          .label,
      contains('Showing Rising performances for discovery'),
    );
    semantics.dispose();
  });

  testWidgets('empty Stage offers only working product destinations', (
    tester,
  ) async {
    var createCalls = 0;
    var clubCalls = 0;
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: const [], hasMore: false),
    );

    await tester.pumpWidget(
      _app(
        repository: repository,
        onCreate: () => createCalls += 1,
        onBrowseClubs: () => clubCalls += 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('THE STAGE IS YOURS'), findsOneWidget);
    await tester.tap(find.text('START A CHANT'));
    await tester.tap(find.text('BROWSE CLUBS'));
    expect(createCalls, 1);
    expect(clubCalls, 1);
  });

  testWidgets('initial feed failure has a real retry', (tester) async {
    var calls = 0;
    final repository = PerformanceRepository(
      pageLoader: (_, _) async {
        calls += 1;
        if (calls == 1) throw StateError('offline');
        return PerformancePage(performances: [_performance()], hasMore: false);
      },
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('The Chant Stage could not be loaded.'), findsOneWidget);

    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();
    expect(find.text('SUPER SAKA EVERY WEEK'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('load more deduplicates an overlapping page', (tester) async {
    final first = _performance(id: 'one');
    final second = _performance(id: 'two');
    final repository = PerformanceRepository(
      pageLoader: (_, cursor) async => cursor == null
          ? PerformancePage(
              performances: [first],
              cursor: 'page-2',
              hasMore: true,
            )
          : PerformancePage(
              performances: [first, second],
              cursor: 'done',
              hasMore: false,
            ),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('LOAD MORE'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('LOAD MORE'));
    await tester.pumpAndSettle();

    expect(find.text('SUPER SAKA EVERY WEEK'), findsNWidgets(2));
    expect(find.byType(PerformanceCard), findsNWidgets(2));
  });

  testWidgets('Stage remains scrollable at enlarged text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          performanceRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: ChantStageScreen(
            onCreate: () {},
            onBrowseClubs: () {},
            mediaBuilder: (_, _) => const ColoredBox(color: Color(0xFF59352F)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('OPEN CHANT & LYRICS'));
    expect(find.byKey(const ValueKey('stage-filter-terrace')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
