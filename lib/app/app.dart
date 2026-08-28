import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/songbook_storage.dart';
import 'package:chants/presentation/auth/account_deletion_recovery_screen.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';
import 'package:chants/presentation/auth/account_deletion_pending_screen.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/shell/app_shell.dart';

class ChantApp extends ConsumerWidget {
  const ChantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Addition B: force dark system UI overlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Chants',
      theme: ChantTheme.dark,
      darkTheme: ChantTheme.dark,
      themeMode: ThemeMode.dark, // Addition B: force dark regardless of system
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: authState.when(
        data: (user) => user != null
            ? _SignedInGate(key: ValueKey(user.uid), uid: user.uid)
            : const SignInScreen(),
        loading: () => const _NeutralLoadingScreen(),
        error: (_, _) => const SignInScreen(),
      ),
    );
  }
}

/// Decides the product shell vs the one-time policy acceptance gate for a
/// signed-in user, from their live profile stream.
///
/// - loading (no snapshot yet), or data(null) (profile doc not written yet,
///   e.g. the brief window right after sign-up before createProfile lands):
///   neutral loading, never the gate and never home.
/// - error after a verified profile: keep that last verified gate state.
/// - error before any verified profile: neutral loading, never home.
/// - data(profile) with a stale or missing acceptedPolicyVersion: the gate.
/// - data(profile) accepted at the current version: AppShell.
class _SignedInGate extends ConsumerStatefulWidget {
  final String uid;

  const _SignedInGate({super.key, required this.uid});

  @override
  ConsumerState<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends ConsumerState<_SignedInGate> {
  UserProfile? _lastVerifiedProfile;

  @override
  void didUpdateWidget(covariant _SignedInGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) _lastVerifiedProfile = null;
  }

  Widget _screenFor({
    required UserProfile? profile,
    required SongbookAccountDeletionState localState,
    required SongbookDeletionGateInput deletionInput,
  }) {
    if (localState == SongbookAccountDeletionState.unknown) {
      return AccountDeletionRecoveryScreen(
        onRetry: () =>
            ref.read(accountDeletionServiceProvider).deleteAccount(widget.uid),
        onSignOut: ref.read(authRepositoryProvider).signOut,
      );
    }
    if (localState == SongbookAccountDeletionState.prepared) {
      return AccountDeletionRecoveryScreen(
        statusCheckFailed: true,
        onRetry: () async {
          ref.invalidate(savedSongbookDeletionStateProvider(deletionInput));
        },
        onSignOut: ref.read(authRepositoryProvider).signOut,
      );
    }
    if (localState == SongbookAccountDeletionState.accepted ||
        profile?.deletionPending == true) {
      return AccountDeletionPendingScreen(
        onSignOut: ref.read(authRepositoryProvider).signOut,
      );
    }
    if (profile == null) return const _NeutralLoadingScreen();
    if (profile.acceptedPolicyVersion != kCurrentPolicyVersion) {
      return const PolicyAcceptanceGateScreen();
    }
    return AppShell(uid: widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.uid));
    final profile = profileAsync.when<UserProfile?>(
      data: (profile) {
        _lastVerifiedProfile = profile;
        return profile;
      },
      loading: () => null,
      error: (_, _) => _lastVerifiedProfile,
    );
    final deletionInput = (
      uid: widget.uid,
      serverDeletionPending: profile?.deletionPending ?? false,
    );
    final localState = ref.watch(
      savedSongbookDeletionStateProvider(deletionInput),
    );
    return localState.when(
      data: (state) => _screenFor(
        profile: profile,
        localState: state,
        deletionInput: deletionInput,
      ),
      loading: () => const _NeutralLoadingScreen(),
      error: (_, _) => AccountDeletionRecoveryScreen(
        statusCheckFailed: true,
        onRetry: () async {
          ref.invalidate(savedSongbookDeletionStateProvider(deletionInput));
        },
        onSignOut: ref.read(authRepositoryProvider).signOut,
      ),
    );
  }
}

class _NeutralLoadingScreen extends StatelessWidget {
  const _NeutralLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
