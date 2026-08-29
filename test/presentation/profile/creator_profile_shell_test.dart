import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/creator_profile_repository.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/presentation/create/create_hub_screen.dart';
import 'package:chants/presentation/profile/creator_profile_screen.dart';
import 'package:chants/presentation/profile/edit_creator_profile_screen.dart';
import 'package:chants/presentation/shell/app_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _MockUser extends Mock implements User {
  @override
  String get uid => 'fan-uid';
}

UserProfile _account() {
  final now = DateTime(2026, 8, 27);
  return UserProfile(
    id: 'fan-uid',
    displayName: 'North Bank Leo',
    role: 'user',
    ageConfirmed17Plus: true,
    acceptedPolicyVersion: 'v1',
    acceptedPolicyAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

CreatorProfile _creator({bool hidden = false, bool removed = false}) {
  final now = DateTime(2026, 8, 27);
  return CreatorProfile(
    id: 'fan-uid',
    handle: 'northbankleo',
    displayName: 'North Bank Leo',
    bio: 'Arsenal, away ends and bad ideas until one sticks.',
    followerCount: 12,
    followingCount: 4,
    performanceCount: 3,
    likeCount: 99,
    shareCount: 18,
    hidden: hidden,
    removed: removed,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap({
  required Widget child,
  CreatorProfile? creator,
  CreatorProfileRepository? repository,
}) {
  final user = _MockUser();
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      userProfileProvider(
        'fan-uid',
      ).overrideWith((ref) => Stream.value(_account())),
      creatorProfileProvider(
        'fan-uid',
      ).overrideWith((ref) => Stream.value(creator)),
      performanceDraftRepositoryProvider.overrideWithValue(
        PerformanceDraftRepository(
          ownerDraftsLoader: (_) => Stream.value(const []),
          reviewQueueLoader: () => Stream.value(const []),
          invoker: (_, _) async => const {},
          uploader: ({required ticket, required media, required ownerId}) =>
              throw UnimplementedError(),
        ),
      ),
      if (repository != null)
        creatorProfileRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: child,
    ),
  );
}

void main() {
  testWidgets('Product Clear shell exposes five understandable destinations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        creator: _creator(),
        child: const AppShell(uid: 'fan-uid', initialIndex: 4),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Feed', 'Clubs', 'Create', 'Songbook', 'You']) {
      expect(find.text(label), findsOneWidget);
      expect(find.byKey(ValueKey('primary-nav-$label')), findsOneWidget);
    }
    expect(find.byType(CreatorProfileScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('primary-nav-Create')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateHubScreen), findsOneWidget);
    expect(find.text('GIVE THE NEXT CHANT A FIRST VOICE.'), findsOneWidget);
  });

  testWidgets('Product Clear shell stays usable on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        creator: _creator(),
        child: const AppShell(uid: 'fan-uid', initialIndex: 4),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Feed', 'Clubs', 'Create', 'Songbook', 'You']) {
      expect(find.byKey(ValueKey('primary-nav-$label')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('creator profile remains operable at enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final user = _MockUser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          userProfileProvider(
            'fan-uid',
          ).overrideWith((ref) => Stream.value(_account())),
          creatorProfileProvider(
            'fan-uid',
          ).overrideWith((ref) => Stream.value(_creator())),
          performanceDraftRepositoryProvider.overrideWithValue(
            PerformanceDraftRepository(
              ownerDraftsLoader: (_) => Stream.value(const []),
              reviewQueueLoader: () => Stream.value(const []),
              invoker: (_, _) async => const {},
              uploader: ({required ticket, required media, required ownerId}) =>
                  throw UnimplementedError(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const AppShell(uid: 'fan-uid', initialIndex: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'EDIT CREATOR PROFILE'),
    );
    expect(find.byKey(const ValueKey('primary-nav-Create')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('You shows public identity and separate creator aggregates', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        creator: _creator(),
        child: const CreatorProfileScreen(uid: 'fan-uid'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('North Bank Leo'), findsOneWidget);
    expect(find.text('@northbankleo'), findsOneWidget);
    expect(
      find.text('Arsenal, away ends and bad ideas until one sticks.'),
      findsOneWidget,
    );
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('FOLLOWERS'), findsOneWidget);
    expect(find.text('FOLLOWING'), findsOneWidget);
    expect(find.text('PERFORMANCES'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('You explains an unset public profile without hiding creation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(child: const CreatorProfileScreen(uid: 'fan-uid')),
    );
    await tester.pumpAndSettle();

    expect(find.text('CREATOR PROFILE NOT PUBLIC YET'), findsOneWidget);
    expect(find.text('SET UP CREATOR PROFILE'), findsOneWidget);
    expect(find.textContaining('words-only chants still work'), findsOneWidget);
  });

  testWidgets('creator form keeps values and explains a taken handle', (
    tester,
  ) async {
    final repository = CreatorProfileRepository(
      invoker: (_) async => throw const CreatorProfileException(
        CreatorProfileFailure.handleUnavailable,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        repository: repository,
        child: const EditCreatorProfileScreen(uid: 'fan-uid'),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    expect(find.text('North Bank Leo'), findsOneWidget);
    expect(find.text('north_bank_leo'), findsOneWidget);
    await tester.enterText(fields.at(1), 'taken_handle');
    await tester.enterText(fields.at(2), 'A bio worth keeping.');
    await tester.tap(find.text('SAVE CREATOR PROFILE'));
    await tester.pumpAndSettle();

    expect(find.text('That handle is taken. Try another one.'), findsOneWidget);
    expect(find.text('taken_handle'), findsOneWidget);
    expect(find.text('A bio worth keeping.'), findsOneWidget);
  });

  testWidgets(
    'removed creator identity cannot be republished from the client',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          creator: _creator(removed: true),
          child: const CreatorProfileScreen(uid: 'fan-uid'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This creator profile was removed and is not public.'),
        findsOneWidget,
      );
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'EDIT CREATOR PROFILE'),
      );
      expect(button.onPressed, isNull);
    },
  );
}
