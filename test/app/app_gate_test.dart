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
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/services/account_deletion_service.dart';
import 'package:chants/presentation/auth/account_deletion_pending_screen.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';

// --- Fakes (write boundary only, no logic reimplementation) ---

class _MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-1';
}

class _FakeAuthRepository extends Mock implements AuthRepository {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class _FakeAccountDeletionService extends Mock
    implements AccountDeletionService {
  Object? error;
  int calls = 0;

  @override
  Future<void> deleteAccount(String uid) async {
    calls += 1;
    if (error != null) throw error!;
  }
}

/// HomeScreen independently watches profileRepositoryProvider.profileStream
/// for its own operator-menu check, so any test that expects HomeScreen to
/// render needs this backed by a real (non-throwing) stream too. Calls the
/// factory fresh each time: a single-subscription Stream can only be
/// listened to once, and this repo and userProfileProvider's override both
/// listen independently.
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
  }) {
    final fakeProfileRepo = _FakeProfileRepository()
      ..makeStream = makeProfileStream;
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => authStream),
        profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
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
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets(
      'signed in, profile doc not written yet (data(null)) shows neutral '
      'loading, not the gate',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(null),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
      },
    );

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
        await tester.pump();
        await tester.pump();

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
                Stream.value(_makeProfile(acceptedPolicyVersion: 'v0-old')),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(PolicyAcceptanceGateScreen), findsOneWidget);
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
      await tester.pump();
      await tester.pump();

      expect(find.byType(AccountDeletionPendingScreen), findsOneWidget);
      expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.tap(find.text('SIGN OUT'));
      await tester.pump();
      expect(authRepository.signOutCalls, 1);
    });

    testWidgets(
      'signed in, profile accepted the current version shows HomeScreen',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            authStream: Stream.value(fakeUser as User?),
            makeProfileStream: () => Stream.value(
              _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(PolicyAcceptanceGateScreen), findsNothing);
      },
    );

    testWidgets('an initial profile-stream error never authorizes HomeScreen', (
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
      expect(find.byType(HomeScreen), findsNothing);
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

      profiles.add(
        _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);

      profiles.addError('transient read failure');
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
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
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('account deletion explains background work and failed start', (
      tester,
    ) async {
      final deletionService = _FakeAccountDeletionService()
        ..error = StateError('request failed');
      await tester.pumpWidget(
        wrap(
          authStream: Stream.value(fakeUser as User?),
          makeProfileStream: () => Stream.value(
            _makeProfile(acceptedPolicyVersion: kCurrentPolicyVersion),
          ),
          accountDeletionService: deletionService,
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Cleanup may continue briefly'),
        findsOneWidget,
      );
      expect(find.textContaining('This cannot be undone'), findsOneWidget);

      await tester.tap(find.text('DELETE MY ACCOUNT'));
      await tester.pumpAndSettle();

      expect(deletionService.calls, 1);
      expect(find.textContaining('Deletion did not start'), findsOneWidget);
      expect(
        find.textContaining('Saved Songbook are still available'),
        findsOneWidget,
      );
    });
  });
}
