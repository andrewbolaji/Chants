import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/performance.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/presentation/feed/chant_stage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

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

Performance _performance() {
  final now = DateTime.utc(2026, 8, 27);
  return Performance(
    id: 'performance-1',
    chantId: 'chant-1',
    chantTitle: 'Super Saka Every Week',
    teamId: 'arsenal',
    teamName: 'Arsenal',
    playerName: 'Bukayo Saka',
    chantStatus: 'community',
    creatorId: 'creator-1',
    creatorHandle: 'northbankleo',
    creatorDisplayName: 'North Bank Leo',
    caption: 'If this catches on, I am taking full credit.',
    mediaPath: 'performance-media/performance/source',
    durationMs: 18000,
    publicationState: PerformancePublicationState.approved,
    rankingWeek: '2026-08-24',
    viewCount: 1284,
    likeCount: 214,
    commentCount: 31,
    shareCount: 48,
    uniqueSharerCount: 42,
    weeklyUniqueSharerCount: 12,
    weeklyLikeCount: 80,
    weeklyQualifiedViewCount: 300,
    createdAt: now,
    approvedAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('Chant Stage hierarchy at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/feed/chant_stage_golden_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = PerformanceRepository(
      pageLoader: (_, _) async =>
          PerformancePage(performances: [_performance()], hasMore: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          performanceRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: ChantStageScreen(
            onCreate: () {},
            onBrowseClubs: () {},
            mediaBuilder: (_, _) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE35A45), Color(0xFF1C1C1C)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.graphic_eq,
                  size: 88,
                  color: Color(0xFFE9E0CE),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#1 MOST SHARED'), findsOneWidget);
    expect(find.text('CHANT LAB'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chant_stage.png'),
    );
  });
}
