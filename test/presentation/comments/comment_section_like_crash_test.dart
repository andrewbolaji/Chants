import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/block_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/presentation/comments/comment_section.dart';

// --- Fakes ---

class _MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-1';
}

/// Fake CommentRepository with a controllable stream.
class _FakeCommentRepository implements CommentRepository {
  final StreamController<List<Comment>> controller =
      StreamController<List<Comment>>.broadcast();
  Comment? createdComment;
  bool failCreate = false;
  Object? likeReadError;
  CommentLike? persistedLike;
  int likeReadCalls = 0;

  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return controller.stream;
  }

  @override
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async {
    likeReadCalls++;
    if (likeReadError != null) throw likeReadError!;
    return persistedLike;
  }

  @override
  Future<void> likeComment({
    required String userId,
    required String commentId,
  }) async {}

  @override
  Future<void> unlikeComment({
    required String userId,
    required String commentId,
  }) async {}

  @override
  Future<void> createComment(Comment comment) async {
    if (failCreate) throw StateError('write failed');
    createdComment = comment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBlockRepository extends Mock implements BlockRepository {
  bool failUnblock = false;

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String blockedDisplayName,
  }) async {}

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    if (failUnblock) throw StateError('unblock failed');
  }
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) {
    return Stream.value(
      UserProfile(
        id: userId,
        displayName: 'TestUser',
        role: 'user',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Helpers ---

Comment _makeComment({
  String id = 'comment-1',
  int likeCount = 0,
  String body = 'Test comment body',
  String userId = 'other-user',
  String displayName = 'OtherUser',
  String? parentCommentId,
  DateTime? createdAt,
}) {
  return Comment(
    id: id,
    chantId: 'chant-1',
    userId: userId,
    displayName: displayName,
    body: body,
    parentCommentId: parentCommentId,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    likeCount: likeCount,
  );
}

void main() {
  late _FakeCommentRepository fakeCommentRepo;
  late _FakeProfileRepository fakeProfileRepo;
  late _FakeBlockRepository fakeBlockRepo;
  final fakeUser = _MockUser();

  setUp(() {
    fakeCommentRepo = _FakeCommentRepository();
    fakeProfileRepo = _FakeProfileRepository();
    fakeBlockRepo = _FakeBlockRepository();
  });

  tearDown(() {
    fakeCommentRepo.controller.close();
  });

  Widget wrap({double textScale = 1}) {
    return ProviderScope(
      overrides: [
        commentRepositoryProvider.overrideWithValue(fakeCommentRepo),
        profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        blockRepositoryProvider.overrideWithValue(fakeBlockRepo),
        authStateProvider.overrideWith(
          (ref) => Stream.value(fakeUser as User?),
        ),
        blockedUserIdsProvider.overrideWith(
          (ref, userId) => Stream.value(<String>{}),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CommentSection(chantId: 'chant-1', commentCount: 0),
          ),
        ),
      ),
    );
  }

  testWidgets('liking a comment then receiving a stream update does not crash '
      '(no setState during build)', (tester) async {
    // Mount the widget.
    await tester.pumpWidget(wrap());

    // Emit initial comment list with one comment at likeCount 0.
    final comment = _makeComment(likeCount: 0);
    fakeCommentRepo.controller.add([comment]);
    await tester.pumpAndSettle();

    // Verify the comment is rendered.
    expect(find.text('Test comment body'), findsOneWidget);

    // Tap the like (heart icon).
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    // Heart should now be filled (optimistic).
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // Now the server stream delivers an updated snapshot with likeCount = 1.
    // Before the fix, this triggers the crash: the StreamBuilder rebuilds,
    // and _reconcileServerCount calls setState() during build, which throws
    // a FlutterError that fails the test.
    final updatedComment = _makeComment(likeCount: 1);
    fakeCommentRepo.controller.add([updatedComment]);
    await tester.pumpAndSettle();

    // If we reach here without a FlutterError, the bug is fixed.
    // The like should still be shown correctly after reconciliation.
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    'optimistic like shows immediately, then settles with server count',
    (tester) async {
      await tester.pumpWidget(wrap());

      // Emit comment with likeCount 5.
      fakeCommentRepo.controller.add([_makeComment(likeCount: 5)]);
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);

      // Like it - optimistic increment.
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      expect(find.text('6'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Server catches up with likeCount 6.
      fakeCommentRepo.controller.add([_makeComment(likeCount: 6)]);
      await tester.pumpAndSettle();

      // Still 6, not double-counted.
      expect(find.text('6'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    },
  );

  testWidgets(
    'groups replies below their parent in chronological order and hides orphans',
    (tester) async {
      await tester.pumpWidget(wrap());
      final now = DateTime.now();
      final parent = _makeComment(
        id: 'parent-1',
        body: 'Parent comment',
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      final olderReply = _makeComment(
        id: 'reply-1',
        body: 'Older reply',
        parentCommentId: parent.id,
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      final newerReply = _makeComment(
        id: 'reply-2',
        body: 'Newer reply',
        parentCommentId: parent.id,
        createdAt: now.subtract(const Duration(hours: 1)),
      );
      final orphan = _makeComment(
        id: 'orphan',
        body: 'Orphan reply',
        parentCommentId: 'missing-parent',
      );

      fakeCommentRepo.controller.add([newerReply, orphan, parent, olderReply]);
      await tester.pumpAndSettle();

      expect(find.text('Orphan reply'), findsNothing);
      expect(find.text('Reply'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Parent comment')).dy,
        lessThan(tester.getTopLeft(find.text('Older reply')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Older reply')).dy,
        lessThan(tester.getTopLeft(find.text('Newer reply')).dy),
      );
    },
  );

  testWidgets('reply submission persists the parent ID', (tester) async {
    await tester.pumpWidget(wrap());
    fakeCommentRepo.controller.add([
      _makeComment(
        id: 'parent-1',
        body: 'Parent comment',
        displayName: 'FunnyFan',
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reply'));
    await tester.pump();
    expect(find.text('Replying to FunnyFan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Direct answer');
    await tester.pump();
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNotNull);
    sendButton.onPressed!();
    await tester.pumpAndSettle();

    expect(fakeCommentRepo.createdComment?.parentCommentId, 'parent-1');
    expect(fakeCommentRepo.createdComment?.body, 'Direct answer');
    expect(find.text('Replying to FunnyFan'), findsNothing);
  });

  testWidgets('failed reply preserves its draft and reply context', (
    tester,
  ) async {
    fakeCommentRepo.failCreate = true;
    await tester.pumpWidget(wrap());
    fakeCommentRepo.controller.add([
      _makeComment(
        id: 'parent-1',
        body: 'Parent comment',
        displayName: 'FunnyFan',
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reply'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.pump();
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNotNull);
    sendButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Replying to FunnyFan'), findsOneWidget);
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(
      find.text('Could not post your comment. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('failed persisted-like read is contained and retried', (
    tester,
  ) async {
    fakeCommentRepo.likeReadError = StateError('read failed');
    await tester.pumpWidget(wrap());
    final comment = _makeComment();
    fakeCommentRepo.controller.add([comment]);
    await tester.pumpAndSettle();

    expect(fakeCommentRepo.likeReadCalls, 1);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    fakeCommentRepo.likeReadError = null;
    fakeCommentRepo.persistedLike = CommentLike(
      id: 'test-user-1_comment-1',
      commentId: 'comment-1',
      userId: 'test-user-1',
      value: 1,
      createdAt: DateTime.now(),
      appliedValue: 1,
    );
    fakeCommentRepo.controller.add([comment]);
    await tester.pumpAndSettle();

    expect(fakeCommentRepo.likeReadCalls, 2);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty comments wrap at 390 wide and 1.8x text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(textScale: 1.8));
    fakeCommentRepo.controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('No comments yet. Be the first.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed block Undo is contained and explains recovery', (
    tester,
  ) async {
    fakeBlockRepo.failUnblock = true;
    await tester.pumpWidget(wrap());
    fakeCommentRepo.controller.add([_makeComment()]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block this user'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Block'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not unblock this user. Try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
