import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/sport_repository.dart';
import 'package:chants/data/repositories/competition_repository.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/data/repositories/report_repository.dart';
import 'package:chants/data/repositories/feedback_repository.dart';

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

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(),
);

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
