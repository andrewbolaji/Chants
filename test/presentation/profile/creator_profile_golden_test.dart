import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/presentation/shell/app_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'fan-uid';
}

Future<void> _loadFonts() async {
  const fonts = {
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
    'Fraunces': 'assets/fonts/Fraunces-Variable.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  testWidgets('creator identity and Product Clear shell at 390 by 844', (
    tester,
  ) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/profile/creator_profile_golden_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime(2026, 8, 27);
    final user = _User();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          userProfileProvider('fan-uid').overrideWith(
            (ref) => Stream.value(
              UserProfile(
                id: 'fan-uid',
                displayName: 'North Bank Leo',
                role: 'user',
                ageConfirmed17Plus: true,
                acceptedPolicyVersion: 'v1',
                acceptedPolicyAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          ),
          creatorProfileProvider('fan-uid').overrideWith(
            (ref) => Stream.value(
              CreatorProfile(
                id: 'fan-uid',
                handle: 'northbankleo',
                displayName: 'North Bank Leo',
                bio: 'Arsenal, away ends and bad ideas until one sticks.',
                followerCount: 12,
                followingCount: 4,
                performanceCount: 3,
                likeCount: 99,
                shareCount: 18,
                hidden: false,
                removed: false,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          ),
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
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const AppShell(uid: 'fan-uid', initialIndex: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('@northbankleo'), findsOneWidget);
    expect(find.byKey(const ValueKey('primary-nav-Create')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/creator_profile_shell.png'),
    );
  });
}
