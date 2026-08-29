import 'package:flutter/material.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/auth/email_sign_in_screen.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';
import 'package:chants/presentation/auth/password_reset_screen.dart';
import 'package:chants/presentation/auth/magic_link_screen.dart';
import 'package:chants/presentation/auth/phone_auth_screen.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:chants/presentation/browse/competition_screen.dart';
import 'package:chants/presentation/browse/player_screen.dart';
import 'package:chants/presentation/browse/team_screen.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';
import 'package:chants/presentation/moderation/moderation_screen.dart';
import 'package:chants/presentation/feedback/feedback_screen.dart';
import 'package:chants/presentation/saved/saved_chant_detail_screen.dart';
import 'package:chants/presentation/saved/saved_club_screen.dart';
import 'package:chants/presentation/saved/saved_songbook_screen.dart';
import 'package:chants/presentation/submit/submit_chant_screen.dart';
import 'package:chants/presentation/settings/blocked_users_screen.dart';
import 'package:chants/presentation/settings/sign_in_methods_screen.dart';
import 'package:chants/presentation/profile/edit_creator_profile_screen.dart';
import 'package:chants/presentation/profile/public_creator_profile_screen.dart';
import 'package:chants/presentation/profile/creator_notifications_screen.dart';
import 'package:chants/presentation/create/perform_chant_screen.dart';

class ChantDetailRouteArguments {
  final Chant chant;
  final Team? team;

  const ChantDetailRouteArguments({required this.chant, this.team});
}

class SavedClubRouteArguments {
  final String uid;
  final String teamId;

  const SavedClubRouteArguments({required this.uid, required this.teamId});
}

class SavedChantRouteArguments {
  final String uid;
  final String chantId;
  final String? teamId;

  const SavedChantRouteArguments({
    required this.uid,
    required this.chantId,
    this.teamId,
  });
}

class AppRouter {
  static const String signIn = '/sign-in';
  static const String emailSignIn = '/sign-in/email';
  static const String signUp = '/sign-up';
  static const String passwordReset = '/password-reset';
  static const String magicLink = '/sign-in/email-link';
  static const String phoneAuth = '/sign-in/phone';
  static const String home = '/';
  static const String contentPolicy = '/content-policy';
  static const String competition = '/competition';
  static const String team = '/team';
  static const String player = '/player';
  static const String chantDetail = '/chant';
  static const String submitChant = '/submit';
  static const String moderation = '/moderation';
  static const String feedback = '/feedback';
  static const String blockedUsers = '/blocked-users';
  static const String signInMethods = '/sign-in-methods';
  static const String savedSongbook = '/saved';
  static const String savedClub = '/saved/club';
  static const String savedChant = '/saved/chant';
  static const String editCreatorProfile = '/creator/edit';
  static const String creatorProfile = '/creator';
  static const String creatorNotifications = '/creator/activity';
  static const String performChant = '/perform';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case emailSignIn:
        return MaterialPageRoute(builder: (_) => const EmailSignInScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case passwordReset:
        return MaterialPageRoute(builder: (_) => const PasswordResetScreen());
      case magicLink:
        final linkToCurrentUser = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => MagicLinkScreen(linkToCurrentUser: linkToCurrentUser),
        );
      case phoneAuth:
        final linkToCurrentUser = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => PhoneAuthScreen(linkToCurrentUser: linkToCurrentUser),
        );
      case contentPolicy:
        return MaterialPageRoute(builder: (_) => const ContentPolicyScreen());
      case competition:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => CompetitionScreen(
            competitionId: args['id']!,
            competitionName: args['name']!,
          ),
        );
      case team:
        final t = settings.arguments as Team;
        return MaterialPageRoute(builder: (_) => TeamScreen(team: t));
      case player:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PlayerScreen(
            player: args['player'] as Player,
            sportId: args['sportId'] as String?,
            competitionId: args['competitionId'] as String?,
          ),
        );
      case chantDetail:
        final rawArguments = settings.arguments;
        final arguments = rawArguments is ChantDetailRouteArguments
            ? rawArguments
            : ChantDetailRouteArguments(chant: rawArguments as Chant);
        return MaterialPageRoute(
          builder: (_) =>
              ChantDetailScreen(chant: arguments.chant, team: arguments.team),
        );
      case submitChant:
        final args = settings.arguments as Map<String, String?>;
        return MaterialPageRoute(
          builder: (_) => SubmitChantScreen(
            teamId: args['teamId']!,
            sportId: args['sportId']!,
            competitionId: args['competitionId']!,
            prefilledPlayerId: args['playerId'],
          ),
        );
      case moderation:
        return MaterialPageRoute(builder: (_) => const ModerationScreen());
      case feedback:
        return MaterialPageRoute(builder: (_) => const FeedbackScreen());
      case blockedUsers:
        return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
      case signInMethods:
        return MaterialPageRoute(builder: (_) => const SignInMethodsScreen());
      case savedSongbook:
        final uid = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => SavedSongbookScreen(uid: uid));
      case savedClub:
        final arguments = settings.arguments as SavedClubRouteArguments;
        return MaterialPageRoute(
          builder: (_) =>
              SavedClubScreen(uid: arguments.uid, teamId: arguments.teamId),
        );
      case savedChant:
        final arguments = settings.arguments as SavedChantRouteArguments;
        return MaterialPageRoute(
          builder: (_) => SavedChantDetailScreen(
            uid: arguments.uid,
            chantId: arguments.chantId,
            teamId: arguments.teamId,
          ),
        );
      case editCreatorProfile:
        final uid = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => EditCreatorProfileScreen(uid: uid),
        );
      case creatorProfile:
        final creatorId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PublicCreatorProfileScreen(creatorId: creatorId),
        );
      case creatorNotifications:
        return MaterialPageRoute(
          builder: (_) => const CreatorNotificationsScreen(),
        );
      case performChant:
        final chant = settings.arguments as Chant;
        return MaterialPageRoute(
          builder: (_) => PerformChantScreen(chant: chant),
        );
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
