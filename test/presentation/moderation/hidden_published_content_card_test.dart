import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:chants/presentation/moderation/moderation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ModerationRepository extends ModerationRepository {
  final actions = <(String, String, String)>[];

  _ModerationRepository()
    : super(accountDeletionInvoker: () async => {'accepted': true});

  @override
  Future<void> moderatePublishedPerformance({
    required String targetType,
    required String targetId,
    required String action,
  }) async {
    actions.add((targetType, targetId, action));
  }
}

Widget _app(_ModerationRepository moderation, {double textScale = 1}) {
  return ProviderScope(
    overrides: [
      moderationRepositoryProvider.overrideWithValue(moderation),
      performanceRepositoryProvider.overrideWithValue(
        PerformanceRepository(
          pageLoader: (_, _) async =>
              PerformancePage(performances: const [], hasMore: false),
          playbackResolver: (_) async =>
              Uri.parse('https://signed.example.test/performance'),
        ),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        theme: ChantTheme.dark,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HiddenPublishedContentCard(
              targetType: 'performance',
              targetId: 'performance-1',
              label: 'Hidden performance',
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'hidden media has preview, restore, and terminal remove controls',
    (tester) async {
      final moderation = _ModerationRepository();
      await tester.pumpWidget(_app(moderation));

      expect(find.text('PREVIEW'), findsOneWidget);
      expect(find.text('RESTORE'), findsOneWidget);
      expect(find.text('REMOVE'), findsOneWidget);

      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Removal is terminal.'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'REMOVE'),
        ),
      );
      await tester.pumpAndSettle();

      expect(moderation.actions, [('performance', 'performance-1', 'remove')]);
    },
  );

  testWidgets('hidden media can be restored through the server boundary', (
    tester,
  ) async {
    final moderation = _ModerationRepository();
    await tester.pumpWidget(_app(moderation));
    await tester.tap(find.text('RESTORE'));
    await tester.pumpAndSettle();

    expect(moderation.actions, [('performance', 'performance-1', 'unhide')]);
  });

  testWidgets('hidden media actions remain usable at narrow enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(_ModerationRepository(), textScale: 1.8));
    await tester.pumpAndSettle();

    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.text('RESTORE'), findsOneWidget);
    expect(find.text('REMOVE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
