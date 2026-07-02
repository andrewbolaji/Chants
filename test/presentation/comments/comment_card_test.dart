import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/presentation/comments/comment_card.dart';

// --- Helpers ---

Comment _makeComment({
  String id = 'comment-1',
  int likeCount = 0,
  String body = 'Test comment body text',
  String displayName = 'TestUser',
  String userId = 'user-1',
}) {
  return Comment(
    id: id,
    chantId: 'chant-1',
    userId: userId,
    displayName: displayName,
    body: body,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likeCount: likeCount,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('CommentCard', () {
    testWidgets('renders displayName, body, and relative time', (tester) async {
      final comment = _makeComment(
        displayName: 'FanNumber1',
        body: 'Great chant this one',
      );

      await tester.pumpWidget(_wrap(CommentCard(
        comment: comment,
        likeState: CommentLikeState.initial(0),
        isAuthor: false,
      )));

      expect(find.text('FanNumber1'), findsOneWidget);
      expect(find.text('Great chant this one'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('shows report flag for non-author, delete for author',
        (tester) async {
      final comment = _makeComment();

      // Non-author: flag icon, no delete
      await tester.pumpWidget(_wrap(CommentCard(
        comment: comment,
        likeState: CommentLikeState.initial(0),
        isAuthor: false,
      )));
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Author: delete icon, no flag
      await tester.pumpWidget(_wrap(CommentCard(
        comment: comment,
        likeState: CommentLikeState.initial(0),
        isAuthor: true,
      )));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
    });

    testWidgets('like toggle: unfilled heart when not liked, filled when liked',
        (tester) async {
      final comment = _makeComment(likeCount: 3);

      // Not liked
      await tester.pumpWidget(_wrap(CommentCard(
        comment: comment,
        likeState: CommentLikeState.initial(3),
        isAuthor: false,
      )));
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.text('3'), findsOneWidget);

      // Liked (after toggle)
      final likedState = CommentLikeState.initial(3)
          .reconcileFromPersistedLike(1);
      await tester.pumpWidget(_wrap(CommentCard(
        comment: comment,
        likeState: likedState,
        isAuthor: false,
      )));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('hides like count when displayCount is 0', (tester) async {
      final comment = _makeComment(likeCount: 0);
      await tester.pumpWidget(_wrap(CommentCard(
        comment: comment,
        likeState: CommentLikeState.initial(0),
        isAuthor: false,
      )));

      // Heart icon shown, but no count text
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('CommentLikeState', () {
    test('initial state: not liked, delta 0', () {
      final s = CommentLikeState.initial(5);
      expect(s.displayCount, 5);
      expect(s.liked, false);
      expect(s.optimisticDelta, 0);
    });

    test('toggle: like increments display, unlike decrements', () {
      final s = CommentLikeState.initial(5);

      final liked = s.toggle();
      expect(liked.liked, true);
      expect(liked.displayCount, 6);
      expect(liked.busy, true);

      final unliked = liked.confirmWrite().toggle();
      expect(unliked.liked, false);
      expect(unliked.displayCount, 5);
    });

    test('reconcileServerCount collapses delta when not busy', () {
      final s = CommentLikeState.initial(5).toggle().confirmWrite();
      expect(s.displayCount, 6); // liked, delta +1

      final reconciled = s.reconcileServerCount(6);
      expect(reconciled.displayCount, 6);
      expect(reconciled.optimisticDelta, 0);
      expect(reconciled.confirmedLiked, true);
    });

    test(
      'COLD LOAD BUG: without appliedValue reconciliation, a cold load '
      'double-counts the like (server already includes it, client adds +1)',
      () {
        // Server likeCount is 1 (already includes the user's like).
        // The user has a like doc with appliedValue == 1.
        final s = CommentLikeState.initial(1);

        // CORRECT behavior: reconcileFromPersistedLike sees appliedValue == 1,
        // sets confirmedLiked = true, delta = 0. Display = 1.
        final correct = s.reconcileFromPersistedLike(1);
        expect(correct.displayCount, 1,
            reason: 'appliedValue == 1 means server count includes the like');
        expect(correct.liked, true);
        expect(correct.optimisticDelta, 0);

        // BUG scenario: if we ignored appliedValue and naively set liked = true
        // with delta = +1, display would be 2 (double-counted).
        final buggy = CommentLikeState(
          serverLikeCount: 1,
          liked: true,
          confirmedLiked: false, // as if we did not check appliedValue
          busy: false,
          optimisticDelta: 1, // naive +1
        );
        expect(buggy.displayCount, 2,
            reason: 'Without appliedValue reconciliation, the like is double-counted');

        // The fix is reconcileFromPersistedLike: it checks appliedValue and
        // avoids the double-count.
        expect(correct.displayCount, isNot(buggy.displayCount));
      },
    );

    test('cold load with appliedValue absent: server has not processed yet', () {
      // Server likeCount is 0 (CF has not yet processed the like).
      // Like doc exists but appliedValue is null.
      final s = CommentLikeState.initial(0);
      final reconciled = s.reconcileFromPersistedLike(null);

      expect(reconciled.liked, true);
      expect(reconciled.optimisticDelta, 1);
      expect(reconciled.displayCount, 1,
          reason: 'Show expected count until server catches up');
    });
  });
}
