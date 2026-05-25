import 'package:flutter/material.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';
import 'package:chants/presentation/auth/password_reset_screen.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:chants/presentation/browse/competition_screen.dart';
import 'package:chants/presentation/browse/player_screen.dart';
import 'package:chants/presentation/browse/team_screen.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';

class AppRouter {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String passwordReset = '/password-reset';
  static const String home = '/';
  static const String contentPolicy = '/content-policy';
  static const String competition = '/competition';
  static const String team = '/team';
  static const String player = '/player';
  static const String chantDetail = '/chant';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case passwordReset:
        return MaterialPageRoute(builder: (_) => const PasswordResetScreen());
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
        final p = settings.arguments as Player;
        return MaterialPageRoute(builder: (_) => PlayerScreen(player: p));
      case chantDetail:
        final c = settings.arguments as Chant;
        return MaterialPageRoute(
            builder: (_) => ChantDetailScreen(chant: c));
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
