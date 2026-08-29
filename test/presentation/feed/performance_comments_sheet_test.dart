import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/performance_comment.dart';
import 'package:chants/data/repositories/performance_interaction_repository.dart';
import 'package:chants/presentation/feed/performance_comments_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'viewer-1';
}

PerformanceComment _comment({
  required String id,
  String userId = 'creator-1',
  String? parentCommentId,
  String? rootCommentId,
  int depth = 0,
}) {
  final now = DateTime.utc(2026, 8, 28);
  return PerformanceComment(
    id: id,
    performanceId: 'performance-1',
    performanceCreatorId: 'performer-1',
    userId: userId,
    creatorHandle: 'northbankleo',
    creatorDisplayName: 'North Bank Leo',
    body: '@away_end this one keeps going.',
    parentCommentId: parentCommentId,
    rootCommentId: rootCommentId,
    depth: depth,
    mentionedHandles: const ['away_end'],
    hidden: false,
    removed: false,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _app(PerformanceInteractionRepository repository) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_User() as User?)),
      blockedUserIdsProvider.overrideWith(
        (ref, uid) => Stream.value(const <String>{}),
      ),
      performanceInteractionRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: const Scaffold(
        body: PerformanceCommentsSheet(
          performanceId: 'performance-1',
          chantTitle: 'Super Saka',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('reply intent keeps the selected parent and supports @mentions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final calls = <String>[];
    final root = _comment(id: 'root-1');
    final repository = PerformanceInteractionRepository(
      commentLoader: (_) => Stream.value([root]),
      threadLoader: (_, _) => Stream.value([root]),
      commentAction: (performanceId, body, actionId, parentCommentId) async {
        calls.add('$performanceId|$body|$parentCommentId');
        return 'posted-1';
      },
      commentDeleteAction: (_) async {},
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('performance-comment-root-1')),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(find.text('Replying to @northbankleo'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      '@northbankleo sing it again.',
    );
    await tester.tap(find.byTooltip('Post comment'));
    await tester.pumpAndSettle();

    expect(calls, ['performance-1|@northbankleo sing it again.|root-1']);
  });

  testWidgets('deep replies cap indentation and open a focused thread', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final root = _comment(id: 'root-1');
    final levelTwo = _comment(
      id: 'reply-2',
      parentCommentId: 'reply-1',
      rootCommentId: 'root-1',
      depth: 2,
    );
    final deep = _comment(
      id: 'reply-7',
      parentCommentId: 'reply-6',
      rootCommentId: 'root-1',
      depth: 7,
    );
    final repository = PerformanceInteractionRepository(
      commentLoader: (_) => Stream.value([root, levelTwo, deep]),
      threadLoader: (performanceId, rootId) {
        expect(performanceId, 'performance-1');
        expect(rootId, 'root-1');
        return Stream.value([root, levelTwo, deep]);
      },
      commentAction: (_, _, _, _) async => 'posted-1',
      commentDeleteAction: (_) async {},
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('performance-comment-reply-2')))
          .dx,
      tester
          .getTopLeft(find.byKey(const ValueKey('performance-comment-reply-7')))
          .dx,
    );

    await tester.tap(find.text('OPEN THREAD').last);
    await tester.pumpAndSettle();
    expect(find.text('THREAD'), findsOneWidget);
    expect(find.text('REPLY'), findsNWidgets(3));

    await tester.tap(find.text('REPLY').last);
    await tester.pumpAndSettle();
    expect(find.text('Replying to @northbankleo'), findsOneWidget);
  });
}
