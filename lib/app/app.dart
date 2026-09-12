import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/songbook_storage.dart';
import 'package:chants/presentation/auth/account_deletion_recovery_screen.dart';
import 'package:chants/presentation/auth/email_verification_screen.dart';
import 'package:chants/presentation/auth/onboarding_screen.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';
import 'package:chants/presentation/auth/account_deletion_pending_screen.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/auth/magic_link_gate.dart';
import 'package:chants/presentation/auth/launch_reveal_screen.dart';
import 'package:chants/presentation/auth/first_run_orientation_screen.dart';
import 'package:chants/presentation/shell/app_shell.dart';

const kDefaultLaunchRevealDuration = Duration(milliseconds: 2800);
const kFirstRunOrientationWriteTimeout = Duration(seconds: 2);
const kSignedInGateWaitTimeout = Duration(seconds: 15);
const kSignedInProfileRetryDelay = Duration(milliseconds: 650);

class ChantApp extends ConsumerStatefulWidget {
  final Duration launchRevealDuration;

  const ChantApp({
    super.key,
    this.launchRevealDuration = kDefaultLaunchRevealDuration,
  });

  @override
  ConsumerState<ChantApp> createState() => _ChantAppState();
}

class _ChantAppState extends ConsumerState<ChantApp> {
  Timer? _launchTimer;
  bool _launchRevealComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.launchRevealDuration == Duration.zero) {
      _launchRevealComplete = true;
    } else {
      _launchTimer = Timer(widget.launchRevealDuration, () {
        if (mounted) setState(() => _launchRevealComplete = true);
      });
    }
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final reducedMotion = MediaQueryData.fromView(
      View.of(context),
    ).disableAnimations;
    final showLaunchReveal = !_launchRevealComplete && !reducedMotion;

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
      builder: (context, child) => MagicLinkGate(child: child!),
      home: showLaunchReveal
          ? LaunchRevealScreen(animationDuration: widget.launchRevealDuration)
          : authState.when(
              data: (user) => user != null
                  ? _SignedInGate(key: ValueKey(user.uid), uid: user.uid)
                  : const _SignedOutGate(),
              loading: () => const LaunchRevealScreen(
                animationDuration: Duration.zero,
                showProgress: true,
              ),
              error: (_, _) => const SignInScreen(),
            ),
    );
  }
}

/// Shows the versioned product orientation only on the first signed-out run.
///
/// Preference failures never become an account gate. A failed read goes
/// directly to sign-in, and a failed completion write still lets this session
/// continue.
class _SignedOutGate extends ConsumerStatefulWidget {
  const _SignedOutGate();

  @override
  ConsumerState<_SignedOutGate> createState() => _SignedOutGateState();
}

class _SignedOutGateState extends ConsumerState<_SignedOutGate> {
  late final Future<bool> _completionRead;
  bool _completeForSession = false;
  bool _exitInFlight = false;

  @override
  void initState() {
    super.initState();
    _completionRead = ref
        .read(firstRunOrientationRepositoryProvider)
        .isComplete();
  }

  Future<void> _finish({required bool createAccount}) async {
    if (_exitInFlight) return;
    _exitInFlight = true;
    try {
      await ref
          .read(firstRunOrientationRepositoryProvider)
          .markComplete()
          .timeout(kFirstRunOrientationWriteTimeout);
    } catch (error) {
      debugPrint('[FirstRunOrientation] Completion write failed: $error');
    }
    if (!mounted) return;
    setState(() => _completeForSession = true);
    if (createAccount) {
      await Navigator.pushNamed(context, AppRouter.signUp);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completeForSession) return const SignInScreen();
    return FutureBuilder<bool>(
      future: _completionRead,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LaunchRevealScreen(
            animationDuration: Duration.zero,
            showProgress: true,
          );
        }
        if (snapshot.hasError || snapshot.data == true) {
          return const SignInScreen();
        }
        return FirstRunOrientationScreen(
          onSkip: () => _finish(createAccount: false),
          onContinue: () => _finish(createAccount: false),
          onCreateAccount: () => _finish(createAccount: true),
        );
      },
    );
  }
}

/// Decides the product shell vs the one-time policy acceptance gate for a
/// signed-in user, from their live profile stream.
///
/// - loading (no snapshot yet): neutral loading, never a gate or home.
/// - data(null): verified accounts enter recoverable onboarding.
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
  bool _hasVerifiedProfileSnapshot = false;
  int _initialShellIndex = 0;
  Timer? _profileRetryTimer;
  bool _profileRetryScheduled = false;
  bool _profileRetryAttempted = false;

  void _debugGateFailure(String source, Object error) {
    if (!kDebugMode) return;
    debugPrint('Signed-in $source gate failed: ${error.runtimeType}');
  }

  Widget _loadingBoundary(
    SongbookDeletionGateInput deletionInput, {
    required _SignedInGatePhase phase,
    bool recoverImmediately = false,
  }) {
    return _SignedInLoadingBoundary(
      key: ValueKey('signed-in-loading-${widget.uid}'),
      phase: phase,
      recoverImmediately: recoverImmediately,
      onRetry: () => _retryGate(deletionInput),
      onSignOut: ref.read(authRepositoryProvider).signOut,
    );
  }

  void _retryGate(SongbookDeletionGateInput deletionInput) {
    _profileRetryTimer?.cancel();
    _profileRetryScheduled = false;
    _profileRetryAttempted = false;
    ref.invalidate(userProfileProvider(widget.uid));
    ref.invalidate(savedSongbookDeletionStateProvider(deletionInput));
  }

  void _scheduleInitialProfileRetry() {
    if (_profileRetryScheduled || _profileRetryAttempted) return;
    _profileRetryScheduled = true;
    _profileRetryTimer = Timer(kSignedInProfileRetryDelay, () {
      if (!mounted) return;
      _profileRetryScheduled = false;
      _profileRetryAttempted = true;
      ref.invalidate(userProfileProvider(widget.uid));
    });
  }

  @override
  void didUpdateWidget(covariant _SignedInGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _profileRetryTimer?.cancel();
      _profileRetryScheduled = false;
      _profileRetryAttempted = false;
      _lastVerifiedProfile = null;
      _hasVerifiedProfileSnapshot = false;
      _initialShellIndex = 0;
    }
  }

  @override
  void dispose() {
    _profileRetryTimer?.cancel();
    super.dispose();
  }

  Widget _screenFor({
    required UserProfile? profile,
    required bool profileSnapshotAvailable,
    required bool contactVerified,
    required String? email,
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
    if (!profileSnapshotAvailable) {
      return _loadingBoundary(deletionInput, phase: _SignedInGatePhase.profile);
    }
    if (!contactVerified) return EmailVerificationScreen(email: email);
    if (profile == null) {
      return OnboardingScreen(
        onDestinationSelected: (index) {
          _initialShellIndex = index;
        },
      );
    }
    if (profile.acceptedPolicyVersion != kCurrentPolicyVersion) {
      return const PolicyAcceptanceGateScreen();
    }
    return AppShell(uid: widget.uid, initialIndex: _initialShellIndex);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profileAsync = ref.watch(userProfileProvider(widget.uid));
    final profile = profileAsync.when<UserProfile?>(
      data: (profile) {
        _hasVerifiedProfileSnapshot = true;
        _lastVerifiedProfile = profile;
        return profile;
      },
      loading: () => null,
      error: (error, _) {
        _debugGateFailure('profile', error);
        return _lastVerifiedProfile;
      },
    );
    final deletionInput = (
      uid: widget.uid,
      serverDeletionPending: profile?.deletionPending ?? false,
    );
    final localState = ref.watch(
      savedSongbookDeletionStateProvider(deletionInput),
    );
    return localState.when(
      data: (state) {
        if (state == SongbookAccountDeletionState.none &&
            profileAsync.hasError &&
            !_hasVerifiedProfileSnapshot) {
          _scheduleInitialProfileRetry();
          return _loadingBoundary(
            deletionInput,
            phase: _SignedInGatePhase.profile,
            recoverImmediately: _profileRetryAttempted,
          );
        }
        return _screenFor(
          profile: profile,
          profileSnapshotAvailable: _hasVerifiedProfileSnapshot,
          contactVerified:
              user != null &&
              ref.read(authRepositoryProvider).isContactVerified(user),
          email: user?.email,
          localState: state,
          deletionInput: deletionInput,
        );
      },
      loading: () => _loadingBoundary(
        deletionInput,
        phase: _SignedInGatePhase.localSafety,
      ),
      error: (error, _) {
        _debugGateFailure('local deletion-safety', error);
        return AccountDeletionRecoveryScreen(
          statusCheckFailed: true,
          onRetry: () async {
            ref.invalidate(savedSongbookDeletionStateProvider(deletionInput));
          },
          onSignOut: ref.read(authRepositoryProvider).signOut,
        );
      },
    );
  }
}

enum _SignedInGatePhase { profile, localSafety }

class _SignedInLoadingBoundary extends StatefulWidget {
  final _SignedInGatePhase phase;
  final bool recoverImmediately;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  const _SignedInLoadingBoundary({
    super.key,
    required this.phase,
    required this.recoverImmediately,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  State<_SignedInLoadingBoundary> createState() =>
      _SignedInLoadingBoundaryState();
}

class _SignedInLoadingBoundaryState extends State<_SignedInLoadingBoundary> {
  Timer? _waitTimer;
  late bool _timedOut;
  bool _signingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timedOut = widget.recoverImmediately;
    if (!_timedOut) _startWait();
  }

  @override
  void didUpdateWidget(covariant _SignedInLoadingBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recoverImmediately && !oldWidget.recoverImmediately) {
      _waitTimer?.cancel();
      _timedOut = true;
    }
  }

  void _startWait() {
    _waitTimer?.cancel();
    _waitTimer = Timer(kSignedInGateWaitTimeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _retry() {
    if (_signingOut) return;
    widget.onRetry();
    setState(() {
      _timedOut = false;
      _error = null;
    });
    _startWait();
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut().timeout(kSignedInGateWaitTimeout);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _signingOut = false;
        _error = 'Could not sign out. Check your connection and try again.';
      });
    }
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_timedOut) {
      return const LaunchRevealScreen(
        animationDuration: Duration.zero,
        showProgress: true,
      );
    }
    return Scaffold(
      key: const Key('signed-in-loading-recovery'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: Image.asset(
                        'assets/icon/splash.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  Semantics(
                    header: true,
                    child: Text(
                      widget.phase == _SignedInGatePhase.profile
                          ? 'PROFILE COULD NOT LOAD'
                          : 'ACCOUNT CHECK IS TAKING TOO LONG',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppColors.textHeadline,
                            fontSize: 30,
                            height: 1.05,
                          ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    widget.phase == _SignedInGatePhase.profile
                        ? 'Your sign-in worked, but Chants could not securely load your profile. Check your connection, then try again or sign out.'
                        : 'Your sign-in worked, but Chants could not finish its on-device account safety check. Try again or sign out.',
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.md),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                  FilledButton.icon(
                    key: const Key('signed-in-loading-retry'),
                    onPressed: _signingOut ? null : _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('TRY AGAIN'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton(
                    key: const Key('signed-in-loading-sign-out'),
                    onPressed: _signingOut ? null : _signOut,
                    child: _signingOut
                        ? const Text('SIGNING OUT')
                        : const Text('SIGN OUT'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
