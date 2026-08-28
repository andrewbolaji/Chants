import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/models/auth_feature_config.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/blocked_user.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/creator_profile_repository.dart';
import 'package:chants/data/repositories/creator_follow_repository.dart';
import 'package:chants/data/repositories/creator_notification_repository.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/data/repositories/performance_interaction_repository.dart';
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/data/services/performance_media_selection.dart';
import 'package:chants/data/services/performance_share.dart';
import 'package:chants/data/services/creator_share.dart';
import 'package:chants/data/repositories/sport_repository.dart';
import 'package:chants/data/repositories/competition_repository.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/block_repository.dart';
import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/data/repositories/onboarding_repository.dart';
import 'package:chants/data/repositories/magic_link_store.dart';
import 'package:chants/data/repositories/safety_submission_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/repositories/songbook_storage.dart';
import 'package:chants/data/services/account_deletion_service.dart';
import 'package:chants/data/services/magic_link_coordinator.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:chants/data/services/saved_songbook_service.dart';
import 'package:chants/data/models/saved_songbook.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authFeatureConfigProvider = Provider<AuthFeatureConfig>(
  (ref) => AuthFeatureConfig.fromEnvironment(),
);

final magicLinkStoreProvider = Provider<MagicLinkStore>(
  (ref) => MagicLinkStore(),
);

final magicLinkCoordinatorProvider = Provider<MagicLinkCoordinator>(
  (ref) => MagicLinkCoordinator(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final creatorProfileRepositoryProvider = Provider<CreatorProfileRepository>(
  (ref) => CreatorProfileRepository(),
);

final creatorFollowRepositoryProvider = Provider<CreatorFollowRepository>(
  (ref) => CreatorFollowRepository.firebase(),
);

final creatorNotificationRepositoryProvider =
    Provider<CreatorNotificationRepository>(
      (ref) => CreatorNotificationRepository.firebase(),
    );

final performanceRepositoryProvider = Provider<PerformanceRepository>(
  (ref) => PerformanceRepository(),
);

final performanceInteractionRepositoryProvider =
    Provider<PerformanceInteractionRepository>(
      (ref) => PerformanceInteractionRepository.firebase(),
    );

final publicShareRepositoryProvider = Provider<PublicShareRepository>(
  (ref) => PublicShareRepository(),
);

final performanceShareGatewayProvider = Provider<PerformanceShareGateway>(
  (ref) => PlatformPerformanceShareGateway(),
);

final creatorShareGatewayProvider = Provider<CreatorShareGateway>(
  (ref) => PlatformCreatorShareGateway(),
);

final performanceDraftRepositoryProvider = Provider<PerformanceDraftRepository>(
  (ref) => PerformanceDraftRepository(),
);

final performanceMediaSelectorProvider = Provider<PerformanceMediaSelector>(
  (ref) => PerformanceMediaSelector(),
);

final sportRepositoryProvider = Provider<SportRepository>(
  (ref) => SportRepository(),
);

final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) => CompetitionRepository(),
);

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(),
);

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepository(),
);

final chantRepositoryProvider = Provider<ChantRepository>(
  (ref) => ChantRepository(),
);

final voteRepositoryProvider = Provider<VoteRepository>(
  (ref) => VoteRepository(),
);

final safetySubmissionRepositoryProvider = Provider<SafetySubmissionRepository>(
  (ref) => SafetySubmissionRepository(),
);

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(),
);

final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => BlockRepository(),
);

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(),
);

final chantShareGatewayProvider = Provider<ChantShareGateway>(
  (ref) => PlatformChantShareGateway(),
);

final savedSongbookRepositoryProvider = Provider<SavedSongbookRepository>(
  (ref) => SavedSongbookRepository(
    canAccess: (uid) => ref.read(authStateProvider).valueOrNull?.uid == uid,
  ),
);

final savedSongbookServiceProvider = Provider<SavedSongbookService>((ref) {
  return SavedSongbookService(
    savedRepository: ref.watch(savedSongbookRepositoryProvider),
    chantRepository: ref.watch(chantRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
  );
});

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    moderationRepository: ref.watch(moderationRepositoryProvider),
    savedSongbookRepository: ref.watch(savedSongbookRepositoryProvider),
    signOut: ref.watch(authRepositoryProvider).signOut,
  );
});

final savedSongbookProvider = FutureProvider.autoDispose
    .family<SavedSongbook, String>((ref, uid) {
      return ref.watch(savedSongbookRepositoryProvider).load(uid);
    });

typedef SongbookDeletionGateInput = ({String uid, bool serverDeletionPending});

final savedSongbookDeletionStateProvider = FutureProvider.autoDispose
    .family<SongbookAccountDeletionState, SongbookDeletionGateInput>((
      ref,
      input,
    ) async {
      final repository = ref.watch(savedSongbookRepositoryProvider);
      var state = await repository.accountDeletionState(input.uid);
      if (state == SongbookAccountDeletionState.prepared) {
        state = await repository.retryAccountDeletionArtifactRecovery(
          input.uid,
        );
      }
      if (input.serverDeletionPending &&
          (state == SongbookAccountDeletionState.unknown ||
              state == SongbookAccountDeletionState.accepted)) {
        await repository.confirmAccountDeletionAccepted(input.uid);
        state = await repository.accountDeletionState(input.uid);
      }
      return state;
    });

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Live profile stream for a given user ID. AsyncValue.loading before the
// first snapshot, AsyncValue.data(null) if the profile doc does not exist
// yet (e.g. briefly after sign-up, before createProfile's write lands).
final userProfileProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(profileRepositoryProvider).profileStream(uid);
});

final creatorProfileProvider = StreamProvider.family<CreatorProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(creatorProfileRepositoryProvider).profileStream(uid);
});

final blockedUsersProvider = StreamProvider.family<List<BlockedUser>, String>((
  ref,
  blockerId,
) {
  return ref.watch(blockRepositoryProvider).blockedUsersStream(blockerId);
});

final blockedUserIdsProvider = StreamProvider.family<Set<String>, String>((
  ref,
  blockerId,
) {
  return ref
      .watch(blockRepositoryProvider)
      .blockedUsersStream(blockerId)
      .map((users) => users.map((user) => user.blockedUserId).toSet());
});
