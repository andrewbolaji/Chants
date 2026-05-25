import 'package:flutter/material.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';
import 'package:chants/presentation/auth/password_reset_screen.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';

class AppRouter {
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String passwordReset = '/password-reset';
  static const String home = '/';
  static const String contentPolicy = '/content-policy';

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
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
