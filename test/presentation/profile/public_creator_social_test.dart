import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/creator_notification.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/performance.dart';
import 'package:chants/data/repositories/creator_follow_repository.dart';
import 'package:chants/data/repositories/creator_notification_repository.dart';
import 'package:chants/data/repositories/performance_interaction_repository.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/services/creator_share.dart';
import 'package:chants/presentation/profile/creator_notifications_screen.dart';
import 'package:chants/presentation/profile/public_creator_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'viewer-1';
}

class _CreatorShareGateway implements CreatorShareGateway {
  CreatorSharePayload? payload;

  @override
  Future<void> share(
    CreatorSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {
    this.payload = payload;
  }
}

CreatorProfile _creator() {
  final now = DateTime.utc(2026, 8, 28);
  return CreatorProfile(
    id: 'creator-1',
    handle: 'northbankleo',
    displayName: 'North Bank Leo',
    bio: 'Away ends and bad ideas until one sticks.',
    followerCount: 12,
    followingCount: 4,
    performanceCount: 3,
    likeCount: 99,
    shareCount: 20,
    hidden: false,
    removed: false,
    createdAt: now,
    updatedAt: now,
  );
}

Performance _performance() {
  final now = DateTime.utc(2026, 8, 28);
  return Performance(
    id: 'performance-1',
    chantId: 'chant-1',
    chantTitle: 'Super Saka',
    teamId: 'arsenal',
    teamName: 'Arsenal',
    chantStatus: 'community',
    creatorId: 'creator-1',
    creatorHandle: 'northbankleo',
    creatorDisplayName: 'North Bank Leo',
    caption: 'Away end take.',
    mediaPath: 'performance-media/performance-1/source',
    durationMs: 18000,
    publicationState: PerformancePublicationState.approved,
    rankingWeek: '2026-08-24',
    createdAt: now,
    approvedAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('public creator profile can follow and share a stable URL', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final followCalls = <bool>[];
    final shareGateway = _CreatorShareGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          creatorProfileProvider(
            'creator-1',
          ).overrideWith((ref) => Stream.value(_creator())),
          creatorFollowRepositoryProvider.overrideWithValue(
            CreatorFollowRepository(
              followStateLoader: (_, _) async => false,
              followedCreatorLoader: (_) async => const [],
              followAction: (_, following) async {
                followCalls.add(following);
                return true;
              },
            ),
          ),
          publicShareRepositoryProvider.overrideWithValue(
            PublicShareRepository(
              resolver: (_, _) async =>
                  Uri.parse('https://chantsfc.com/creators/northbankleo'),
            ),
          ),
          creatorShareGatewayProvider.overrideWithValue(shareGateway),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          home: const PublicCreatorProfileScreen(creatorId: 'creator-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Away ends and bad ideas until one sticks.'),
      findsOneWidget,
    );
    await tester.tap(find.text('FOLLOW'));
    await tester.pumpAndSettle();
    expect(followCalls, [true]);
    expect(find.text('FOLLOWING'), findsWidgets);
    expect(
      find.bySemanticsLabel('13 followers, 4 following, 3 performances'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Share @northbankleo'));
    await tester.pumpAndSettle();
    expect(
      shareGateway.payload?.text,
      contains('https://chantsfc.com/creators/northbankleo'),
    );
  });

  testWidgets('Activity is private, marks a row read, and opens its actor', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final reads = <String>[];
    final now = DateTime.utc(2026, 8, 28);
    final notification = CreatorNotification(
      id: 'follow-1',
      ownerId: 'viewer-1',
      actorId: 'creator-1',
      actorHandle: 'northbankleo',
      actorDisplayName: 'North Bank Leo',
      type: CreatorNotificationType.creatorFollow,
      performanceId: null,
      commentId: null,
      read: false,
      createdAt: now,
      readAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          creatorNotificationRepositoryProvider.overrideWithValue(
            CreatorNotificationRepository(
              notificationLoader: (_) => Stream.value([notification]),
              readAction: (id) async => reads.add(id),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          routes: {
            AppRouter.creatorProfile: (_) =>
                const Scaffold(body: Text('PUBLIC CREATOR DESTINATION')),
          },
          home: const CreatorNotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('North Bank Leo followed you'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('unread-notification-follow-1')),
          )
          .label,
      'Unread',
    );

    await tester.tap(
      find.byKey(const ValueKey('creator-notification-follow-1')),
    );
    await tester.pumpAndSettle();
    expect(reads, ['follow-1']);
    expect(find.text('PUBLIC CREATOR DESTINATION'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('mention activity opens the performance conversation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.utc(2026, 8, 28);
    final notification = CreatorNotification(
      id: 'mention-1',
      ownerId: 'viewer-1',
      actorId: 'creator-1',
      actorHandle: 'northbankleo',
      actorDisplayName: 'North Bank Leo',
      type: CreatorNotificationType.performanceMention,
      performanceId: 'performance-1',
      commentId: 'comment-1',
      read: true,
      createdAt: now,
      readAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          creatorNotificationRepositoryProvider.overrideWithValue(
            CreatorNotificationRepository(
              notificationLoader: (_) => Stream.value([notification]),
              readAction: (_) async {},
            ),
          ),
          performanceRepositoryProvider.overrideWithValue(
            PerformanceRepository(
              pageLoader: (_, _) async =>
                  PerformancePage(performances: const [], hasMore: false),
              performanceLoader: (_) async => _performance(),
            ),
          ),
          performanceInteractionRepositoryProvider.overrideWithValue(
            PerformanceInteractionRepository(
              commentLoader: (_) => Stream.value(const []),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          home: const CreatorNotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('creator-notification-mention-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Super Saka'), findsOneWidget);
    expect(
      find.text('No comments yet. Be the first voice in the stand.'),
      findsOneWidget,
    );
  });
}
