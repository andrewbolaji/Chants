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

  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return controller.stream;
  }

  @override
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async {
    return null; // no persisted like
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

class _FakeProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) {
    return Stream.value(UserProfile(
      id: userId,
      displayName: 'TestUser',
      role: 'user',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
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
    createdAt:
        createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    likeCount: likeCount,
  );
}

void main() {
  late _FakeCommentRepository fakeCommentRepo;
  late _FakeProfileRepository fakeProfileRepo;
  final fakeUser = _MockUser();

  setUp(() {
    fakeCommentRepo = _FakeCommentRepository();
    fakeProfileRepo = _FakeProfileRepository();
  });

  tearDown(() {
    fakeCommentRepo.controller.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        commentRepositoryProvider.overrideWithValue(fakeCommentRepo),
        profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        authStateProvider
            .overrideWith((ref) => Stream.value(fakeUser as User?)),
        blockedUserIdsProvider.overrideWith(
          (ref, userId) => Stream.value(<String>{}),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommentSection(chantId: 'chant-1', commentCount: 0),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'liking a comment then receiving a stream update does not crash '
    '(no setState during build)',
    (tester) async {
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
    },
  );

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

      fakeCommentRepo.controller.add([
        newerReply,
        orphan,
        parent,
        olderReply,
      ]);
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

  testWidgets('failed reply preserves its draft and reply context',
      (tester) async {
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
    expect(find.text('Could not post your comment. Try again.'), findsOneWidget);
  });
}
