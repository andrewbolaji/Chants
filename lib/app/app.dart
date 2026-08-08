import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';

class ChantApp extends ConsumerWidget {
  const ChantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Addition B: force dark system UI overlay
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Chants',
      theme: ChantTheme.dark,
      darkTheme: ChantTheme.dark,
      themeMode: ThemeMode.dark, // Addition B: force dark regardless of system
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: authState.when(
        data: (user) => user != null
            ? _SignedInGate(uid: user.uid)
            : const SignInScreen(),
        loading: () => const _NeutralLoadingScreen(),
        error: (_, _) => const SignInScreen(),
      ),
    );
  }
}

/// Decides HomeScreen vs the one-time policy acceptance gate for a signed-in
/// user, from their live profile stream.
///
/// - loading (no snapshot yet), or data(null) (profile doc not written yet,
///   e.g. the brief window right after sign-up before createProfile lands):
///   neutral loading, never the gate and never home.
/// - error: fail open to HomeScreen. A transient read failure here must
///   never lock a user out of the app.
/// - data(profile) with a stale or missing acceptedPolicyVersion: the gate.
/// - data(profile) accepted at the current version: HomeScreen.
class _SignedInGate extends ConsumerWidget {
  final String uid;

  const _SignedInGate({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const _NeutralLoadingScreen();
        if (profile.acceptedPolicyVersion != kCurrentPolicyVersion) {
          return const PolicyAcceptanceGateScreen();
        }
        return const HomeScreen();
      },
      loading: () => const _NeutralLoadingScreen(),
      error: (_, _) => const HomeScreen(),
    );
  }
}

class _NeutralLoadingScreen extends StatelessWidget {
  const _NeutralLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
