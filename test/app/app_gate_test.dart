import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chants/app/app.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/data/repositories/creator_profile_repository.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/repositories/songbook_storage.dart';
import 'package:chants/data/services/account_deletion_service.dart';
import 'package:chants/presentation/auth/account_deletion_pending_screen.dart';
import 'package:chants/presentation/auth/account_deletion_recovery_screen.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/auth/email_verification_screen.dart';
import 'package:chants/presentation/auth/onboarding_screen.dart';
import 'package:chants/presentation/profile/creator_profile_screen.dart';
import 'package:chants/presentation/shell/app_shell.dart';

// --- Fakes (write boundary only, no logic reimplementation) ---

class _MockUser extends Mock implements User {
  final bool verified;

  _MockUser({this.verified = true});

  @override
  String get uid => 'test-user-1';

  @override
  bool get emailVerified => verified;

  @override
  String? get email => 'supporter@example.com';

  @override
  String? get phoneNumber => null;

  @override
  List<UserInfo> get providerData => const [];
}

class _FakeAuthRepository extends Mock implements AuthRepository {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  @override
  bool isContactVerified(User user) {
    if (user.emailVerified || (user.phoneNumber?.isNotEmpty ?? false)) {
      return true;
    }
    return user.providerData.any(
      (provider) => const {
        'apple.com',
        'google.com',
        'facebook.com',
      }.contains(provider.providerId),
    );
  }
}

class _FakeAccountDeletionService extends Mock
    implements AccountDeletionService {
  Object? error;
  Completer<void>? pendingRequest;
  int calls = 0;

  @override
  Future<void> deleteAccount(String uid) async {
    calls += 1;
    final request = pendingRequest;
    if (request != null) {
      await request.future;
      return;
    }
    if (error != null) throw error!;
  }
}

class _FakeSavedSongbookRepository extends Mock
    implements SavedSongbookRepository {
  SongbookAccountDeletionState state = SongbookAccountDeletionState.none;
  Object? stateError;
  Object? recoveryError;
  int confirmationCalls = 0;
  int recoveryCalls = 0;

  @override
  Future<SongbookAccountDeletionState> accountDeletionState(String uid) async {
    if (stateError != null) throw stateError!;
    return state;
  }

  @override
  Future<void> confirmAccountDeletionAccepted(String uid) async {
    confirmationCalls += 1;
    state = SongbookAccountDeletionState.none;
  }

  @override
  Future<SongbookAccountDeletionState> retryAccountDeletionArtifactRecovery(
    String uid,
  ) async {
    recoveryCalls += 1;
    if (recoveryError != null) throw recoveryError!;
    state = SongbookAccountDeletionState.none;
    return state;
  }
}

class _FakeProfileRepository implements ProfileRepository {
  Stream<UserProfile?> Function() makeStream = () => const Stream.empty();

  @override
  Stream<UserProfile?> profileStream(String userId) => makeStream();

  @override
  Future<void> createProfile({
    required String userId,
    required String displayName,
    required bool ageConfirmed17Plus,
  }) async {}

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {}
}

class _FakeCreatorProfileRepository extends Mock
    implements CreatorProfileRepository {
  @override
  Stream<Never?> profileStream(String userId) => Stream.value(null);
}

class _FakePerformanceRepository extends PerformanceRepository {
  _FakePerformanceRepository()
    : super(
        pageLoader: (_, _) async =>
            PerformancePage(performances: const [], hasMore: false),
      );
}

class _FakePerformanceDraftRepository extends PerformanceDraftRepository {
  _FakePerformanceDraftRepository()
    : super(
        invoker: (_, _) async => const {},
        uploader: ({required ticket, required media, required ownerId}) =>
            throw UnimplementedError(),
        ownerDraftsLoader: (_) => Stream.value(const []),
        reviewQueueLoader: () => Stream.value(const []),
      );
}

UserProfile _makeProfile({
  String? acceptedPolicyVersion,
  bool deletionPending = false,
}) {
  final now = DateTime(2026, 1, 1);
  return UserProfile(
    id: 'test-user-1',
    displayName: 'Tester',
    role: 'user',
    ageConfirmed17Plus: true,
    deletionPending: deletionPending,
    acceptedPolicyVersion: acceptedPolicyVersion,
    acceptedPolicyAt: acceptedPolicyVersion == null ? null : now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final fakeUser = _MockUser();

  Widget wrap({
    required Stream<User?> authStream,
    required Stream<UserProfile?> Function() makeProfileStream,
    AuthRepository? authRepository,
    AccountDeletionService? accountDeletionService,
    _FakeSavedSongbookRepository? savedSongbookRepository,
  }) {
    final fakeProfileRepo = _FakeProfileRepository()
      ..makeStream = makeProfileStream;
    final fakeAuthRepository = authRepository ?? _FakeAuthRepository();
    final fakeSavedRepository =
        savedSongbookRepository ?? _FakeSavedSongbookRepository();
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => authStream),
        profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        creatorProfileRepositoryProvider.overrideWithValue(
          _FakeCreatorProfileRepository(),
        ),
        performanceRepositoryProvider.overrideWithValue(
          _FakePerformanceRepository(),
        ),
        performanceDraftRepositoryProvider.overrideWithValue(
          _FakePerformanceDraftRepository(),
        ),
        savedSongbookRepositoryProvider.overrideWithValue(fakeSavedRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        if (accountDeletionService != null)
          accountDeletionServiceProvider.overrideWithValue(
            accountDeletionService,
          ),
        userProfileProvider(
          fakeUser.uid,
        ).overrideWith((ref) => makeProfileStream()),
      ],
      child: const ChantApp(),
    );
  }

  Future<void> openAccountMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('primary-nav-You')));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorProfileScreen), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
  }

  group('ChantApp signed-in gate', () {
    testWidgets('signed out shows SignInScreen', (tester) async {
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(null),
          makeProfileStream: () => const Stream.empty(),
        ),
      );
      await tester.pump();

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('signed in, profile stream has not emitted yet shows neutral '
        'loading, not the gate and not home', (tester) async {
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => StreamController<UserProfile?>().stream,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets(
      'verified account with no profile enters recoverable onboarding',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(null),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
        expect(find.byType(AppShell), findsNothing);
      },
    );

    testWidgets('unverified account waits for email verification', (
      tester,
    ) async {
      final unverifiedUser = _MockUser(verified: false);
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(unverifiedUser as User?),
          makeProfileStream: () => Stream.value(null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets(
      'signed in, profile has not accepted the current policy version '
      'shows the acceptance gate',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () =>
                Stream.value(_makeProfile(acceptedPolicyVersion: null)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PolicyAcceptanceGateScreen), findsOneWidget);
      },
    );

    testWidgets(
      'signed in, profile accepted a stale version shows the acceptance '
      'gate',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () =>
                Stream.value(_makeProfile(acceptedPolicyVersion: 'v1')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PolicyAcceptanceGateScreen), findsOneWidget);
      },
    );

    testWidgets(
      'stale-policy gate permits deletion and sign-out without acceptance',
      (tester) async {
        final authRepository = _FakeAuthRepository();
        final deletionService = _FakeAccountDeletionService();
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () =>
                Stream.value(_makeProfile(acceptedPolicyVersion: 'v1')),
            authRepository: authRepository,
            accountDeletionService: deletionService,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('DELETE ACCOUNT'));
        await tester.pumpAndSettle();
        expect(find.text('Delete your account?'), findsOneWidget);
        await tester.tap(find.text('DELETE MY ACCOUNT'));
        await tester.pumpAndSettle();
        expect(deletionService.calls, 1);

        await tester.tap(find.text('SIGN OUT'));
        await tester.pump();
        expect(authRepository.signOutCalls, 1);
      },
    );

    testWidgets('pending deletion takes precedence and signs out', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository();
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => Stream.value(
            _makeProfile(acceptedPolicyVersion: null, deletionPending: true),
          ),
          authRepository: authRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);
      expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);

      await tester.tap(find.text('SIGN OUT'));
      await tester.pump();
      expect(authRepository.signOutCalls, 1);
    });

    testWidgets(
      'unknown local deletion state blocks the product shell and offers durable retry',
      (tester) async {
        final savedRepository = _FakeSavedSongbookRepository()
          ..state = SongbookAccountDeletionState.unknown;
        final deletionService = _FakeAccountDeletionService()
          ..error = const AccountDeletionRequestUnconfirmedException(
            'response lost again',
          );
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(
              _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
            ),
            accountDeletionService: deletionService,
            savedSongbookRepository: savedRepository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccountDeletionRecoveryScreen), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
        expect(find.text('REQUEST NOT CONFIRMED'), findsOneWidget);

        await tester.tap(find.text('TRY DELETION AGAIN'));
        await tester.pumpAndSettle();

        expect(deletionService.calls, 1);
        expect(find.textContaining('still could not confirm'), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
      },
    );

    testWidgets(
      'unknown local deletion state offers recovery before a profile arrives',
      (tester) async {
        final savedRepository = _FakeSavedSongbookRepository()
          ..state = SongbookAccountDeletionState.unknown;
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.error('profile unavailable'),
            accountDeletionService: _FakeAccountDeletionService(),
            savedSongbookRepository: savedRepository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccountDeletionRecoveryScreen), findsOneWidget);
        expect(find.text('REQUEST NOT CONFIRMED'), findsOneWidget);
        expect(find.text('SIGN OUT'), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
      },
    );

    testWidgets(
      'positive pending profile reconciles unknown local deletion state',
      (tester) async {
        final savedRepository = _FakeSavedSongbookRepository()
          ..state = SongbookAccountDeletionState.unknown;
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(
              _makeProfile(
                acceptedPolicyVersion: kCurrentPolicyVersion,
                deletionPending: true,
              ),
            ),
            authRepository: _FakeAuthRepository(),
            savedSongbookRepository: savedRepository,
          ),
        );
        await tester.pumpAndSettle();

        expect(savedRepository.confirmationCalls, 1);
        expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
      },
    );

    testWidgets('prepared local state recovers without process relaunch', (
      tester,
    ) async {
      final savedRepository = _FakeSavedSongbookRepository()
        ..state = SongbookAccountDeletionState.prepared;
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => Stream.value(
            _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
          ),
          savedSongbookRepository: savedRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(savedRepository.recoveryCalls, 1);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AccountDeletionRecoveryScreen), findsNothing);
    });

    testWidgets('failed prepared recovery stays closed and retries real work', (
      tester,
    ) async {
      final savedRepository = _FakeSavedSongbookRepository()
        ..state = SongbookAccountDeletionState.prepared
        ..recoveryError = StateError('disk unavailable');
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => Stream.value(
            _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
          ),
          savedSongbookRepository: savedRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(savedRepository.recoveryCalls, 1);
      expect(find.text('RECOVERY NEEDED'), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      await tester.tap(find.text('TRY RECOVERY'));
      await tester.pumpAndSettle();

      expect(savedRepository.recoveryCalls, 2);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('local deletion status failure blocks the product shell', (
      tester,
    ) async {
      final savedRepository = _FakeSavedSongbookRepository()
        ..stateError = StateError('disk unavailable');
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => Stream.value(
            _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
          ),
          authRepository: _FakeAuthRepository(),
          savedSongbookRepository: savedRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountDeletionRecoveryScreen), findsOneWidget);
      expect(find.text('RECOVERY NEEDED'), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets(
      'signed in, profile accepted the current version shows the product shell',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(
              _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
      },
    );

    testWidgets('an initial profile-stream error never authorizes the shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => Stream.error('transient read failure'),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
    });

    testWidgets('a later stream error keeps the last verified active gate', (
      tester,
    ) async {
      final profiles = StreamController<UserProfile?>.broadcast();
      addTearDown(profiles.close);
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => profiles.stream,
        ),
      );
      await tester.pump();

      profiles.add(_makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);

      profiles.addError('transient read failure');
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
    });

    testWidgets('a later stream error keeps the pending deletion gate', (
      tester,
    ) async {
      final profiles = StreamController<UserProfile?>.broadcast();
      addTearDown(profiles.close);
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => profiles.stream,
          authRepository: _FakeAuthRepository(),
        ),
      );
      await tester.pump();

      profiles.add(
        _makeProfile(
          acceptedPolicyVersion: kCurrentPolicyVersion,
          deletionPending: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);

      profiles.addError('transient read failure');
      await tester.pump();
      await tester.pump();

      expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets(
      'account deletion explains background work and unknown result',
      (tester) async {
        final deletionService = _FakeAccountDeletionService()
          ..error = const AccountDeletionRequestUnconfirmedException(
            'response lost',
          );
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(
              _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
            ),
            accountDeletionService: deletionService,
          ),
        );
        await tester.pumpAndSettle();

        await openAccountMenu(tester);
        await tester.tap(find.text('Delete account'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Media cleanup can continue'),
          findsOneWidget,
        );
        expect(find.textContaining('This cannot be undone'), findsOneWidget);

        await tester.tap(find.text('DELETE MY ACCOUNT'));
        await tester.pumpAndSettle();

        expect(deletionService.calls, 1);
        expect(find.textContaining('could not confirm'), findsOneWidget);
        expect(find.textContaining('locked for safety'), findsOneWidget);
      },
    );

    for (final scenario in <({String name, Object error})>[
      (
        name: 'unconfirmed response',
        error: const AccountDeletionRequestUnconfirmedException(
          'response lost',
        ),
      ),
      (name: 'generic error', error: StateError('request start failed')),
    ]) {
      testWidgets(
        'late ${scenario.name} does not access disposed shell state',
        (tester) async {
          final profiles = StreamController<UserProfile?>.broadcast();
          final pendingRequest = Completer<void>();
          final deletionService = _FakeAccountDeletionService()
            ..pendingRequest = pendingRequest;
          addTearDown(profiles.close);

          await tester.pumpWidget(
            wrap(
              authStream: Stream.value(fakeUser as User?),
              makeProfileStream: () => profiles.stream,
              accountDeletionService: deletionService,
            ),
          );
          await tester.pump();

          profiles.add(
            _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AppShell), findsOneWidget);

          await openAccountMenu(tester);
          await tester.tap(find.text('Delete account'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('DELETE MY ACCOUNT'));
          await tester.pump();
          expect(deletionService.calls, 1);

          profiles.add(
            _makeProfile(
              acceptedPolicyVersion: kCurrentPolicyVersion,
              deletionPending: true,
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);
          expect(find.byType(AppShell), findsNothing);

          pendingRequest.completeError(scenario.error);
          await tester.pump();
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);
          expect(find.byType(AppShell), findsNothing);
        },
      );
    }
  });
}
