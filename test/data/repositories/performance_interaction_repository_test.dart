import 'package:chants/data/models/performance_comment.dart';
import 'package:chants/data/repositories/performance_interaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'forwards like and qualified-view intent through callable boundaries',
    () async {
      final calls = <String>[];
      final repository = PerformanceInteractionRepository(
        likeAction: (performanceId, liked) async {
          calls.add('like:$performanceId:$liked');
        },
        viewAction: (performanceId) async {
          calls.add('view:$performanceId');
        },
        shareAction: (performanceId) async {
          calls.add('share:$performanceId');
          return true;
        },
        likeLoader: (userId, performanceId) async {
          calls.add('state:$userId:$performanceId');
          return true;
        },
      );

      expect(
        await repository.isLiked(
          userId: 'fan-1',
          performanceId: 'performance-1',
        ),
        isTrue,
      );
      await repository.setLiked(performanceId: 'performance-1', liked: false);
      await repository.recordQualifiedView('performance-1');
      expect(await repository.recordShare('performance-1'), isTrue);

      expect(calls, [
        'state:fan-1:performance-1',
        'like:performance-1:false',
        'view:performance-1',
        'share:performance-1',
      ]);
    },
  );

  test('keeps one client action ID across a comment request', () async {
    final calls = <String>[];
    final repository = PerformanceInteractionRepository(
      commentLoader: (_) => Stream.value(const <PerformanceComment>[]),
      commentAction: (performanceId, body, actionId, parentCommentId) async {
        calls.add('$performanceId:$body:$actionId:$parentCommentId');
        return 'comment-1';
      },
      commentDeleteAction: (commentId) async {
        calls.add('delete:$commentId');
      },
    );

    expect(
      await repository.createComment(
        performanceId: 'performance-1',
        body: 'Sing it again.',
        clientActionId: 'request-1',
        parentCommentId: 'parent-1',
      ),
      'comment-1',
    );
    await repository.deleteComment('comment-1');
    expect(calls, [
      'performance-1:Sing it again.:request-1:parent-1',
      'delete:comment-1',
    ]);
  });

  test('client action IDs are parser-safe and distinct', () {
    final first = PerformanceInteractionRepository.newClientActionId();
    final second = PerformanceInteractionRepository.newClientActionId();

    expect(first, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(second, isNot(first));
  });
}
