import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/models/blocked_user.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/sport_repository.dart';
import 'package:chants/data/repositories/competition_repository.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/data/repositories/report_repository.dart';
import 'package:chants/data/repositories/user_report_repository.dart';
import 'package:chants/data/repositories/feedback_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/block_repository.dart';
import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/services/account_deletion_service.dart';
import 'package:chants/data/services/saved_songbook_service.dart';
import 'package:chants/data/models/saved_songbook.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
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

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(),
);

final userReportRepositoryProvider = Provider<UserReportRepository>(
  (ref) => UserReportRepository(),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(),
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
  );
});

final savedSongbookProvider = FutureProvider.autoDispose
    .family<SavedSongbook, String>((ref, uid) {
      return ref.watch(savedSongbookRepositoryProvider).load(uid);
    });

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Live profile stream for a given user ID. AsyncValue.loading before the
// first snapshot, AsyncValue.data(null) if the profile doc does not exist
// yet (e.g. briefly after sign-up, before createProfile's write lands).
final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(profileRepositoryProvider).profileStream(uid);
});

final blockedUsersProvider =
    StreamProvider.family<List<BlockedUser>, String>((ref, blockerId) {
  return ref.watch(blockRepositoryProvider).blockedUsersStream(blockerId);
});

final blockedUserIdsProvider =
    StreamProvider.family<Set<String>, String>((ref, blockerId) {
  return ref.watch(blockRepositoryProvider).blockedUsersStream(blockerId).map(
        (users) => users.map((user) => user.blockedUserId).toSet(),
      );
});
