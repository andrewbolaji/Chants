import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/presentation/comments/comment_card.dart';

// --- Helpers ---

Comment _makeComment({int likeCount = 1}) {
  return Comment(
    id: 'comment-1',
    chantId: 'chant-1',
    userId: 'user-1',
    displayName: 'TestUser',
    body: 'Synthetic test comment body',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    likeCount: likeCount,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// Reads the displayed like count from the real CommentCard widget tree.
/// Returns null if the count text is not shown (displayCount == 0).
String? _renderedLikeCount(WidgetTester tester) {
  // The like count is in the Row with the heart icon.
  // Find all Text widgets and look for the one next to a heart icon.
  final allTexts = tester.widgetList<Text>(find.byType(Text));
  for (final t in allTexts) {
    // The like count is a short numeric string near the heart
    final data = t.data;
    if (data != null && RegExp(r'^\d+$').hasMatch(data)) {
      return data;
    }
  }
  return null;
}

void main() {
  group('Like reconciliation on cold load (red-then-green)', () {
    // THE BUG: On cold load, the server likeCount is 1 (already includes the
    // user's like). If we ignore appliedValue and naively set optimisticDelta
    // to +1 (because "the user has liked"), the real CommentCard widget renders
    // "2" instead of "1". This is the cold-load double-count.
    //
    // THE FIX: reconcileFromPersistedLike checks appliedValue. When
    // appliedValue == 1 (CF has processed the like), it sets confirmedLiked =
    // true and delta = 0, so display = serverLikeCount + 0 = 1.

    testWidgets(
      'RED: without appliedValue reconciliation, the real widget shows 2 '
      '(double-counted) instead of 1',
      (tester) async {
        // Server likeCount is 1 (includes the user's like).
        final comment = _makeComment(likeCount: 1);

        // Simulate the bug: ignore appliedValue, naively set liked + delta +1.
        final buggyState = CommentLikeState(
          serverLikeCount: 1,
          liked: true,
          confirmedLiked: false, // did not check appliedValue
          busy: false,
          optimisticDelta: 1, // naive: "user liked, so +1"
        );

        await tester.pumpWidget(_wrap(CommentCard(
          comment: comment,
          likeState: buggyState,
          isAuthor: false,
        )));

        // The bug: widget renders "2" (1 server + 1 naive delta).
        expect(_renderedLikeCount(tester), '2',
            reason: 'Without appliedValue reconciliation, the like is double-counted');

        // This is WRONG. The correct count should be 1.
        expect(buggyState.displayCount, isNot(1),
            reason: 'Confirms the buggy state does NOT show the correct count');
      },
    );

    testWidgets(
      'GREEN: with appliedValue reconciliation, the real widget shows 1 '
      '(correct count, no double-counting)',
      (tester) async {
        // Server likeCount is 1 (includes the user's like).
        final comment = _makeComment(likeCount: 1);

        // The fix: reconcileFromPersistedLike sees appliedValue == 1,
        // knows the server count already includes the like, and sets delta = 0.
        final correctState =
            CommentLikeState.initial(1).reconcileFromPersistedLike(1);

        await tester.pumpWidget(_wrap(CommentCard(
          comment: comment,
          likeState: correctState,
          isAuthor: false,
        )));

        // Correct: widget renders "1" (1 server + 0 delta).
        expect(_renderedLikeCount(tester), '1',
            reason: 'With appliedValue reconciliation, the count is correct');

        // And the heart is filled (liked).
        expect(find.byIcon(Icons.favorite), findsOneWidget);

        // Confirm the state is correct
        expect(correctState.displayCount, 1);
        expect(correctState.liked, true);
        expect(correctState.optimisticDelta, 0);
        expect(correctState.confirmedLiked, true);
      },
    );
  });
}
