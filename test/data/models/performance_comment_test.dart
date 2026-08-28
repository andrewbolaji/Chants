import 'package:chants/data/models/performance_comment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the exact public performance comment projection', () {
    final now = DateTime.utc(2026, 8, 28);
    final comment = PerformanceComment.fromJson({
      'schemaVersion': 2,
      'performanceId': 'performance-1',
      'performanceCreatorId': 'creator-1',
      'userId': 'commenter-1',
      'creatorHandle': 'northbankleo',
      'creatorDisplayName': 'North Bank Leo',
      'body': 'This one could travel.',
      'parentCommentId': 'parent-1',
      'rootCommentId': 'root-1',
      'depth': 3,
      'mentionedHandles': ['saka_fan'],
      'hidden': false,
      'removed': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, id: 'comment-1');

    expect(comment.id, 'comment-1');
    expect(comment.creatorHandle, 'northbankleo');
    expect(comment.isVisible, isTrue);
    expect(comment.parentCommentId, 'parent-1');
    expect(comment.rootCommentId, 'root-1');
    expect(comment.displayDepth, 2);
    expect(comment.mentionedHandles, ['saka_fan']);
  });

  test('rejects an unsupported comment schema', () {
    expect(
      () => PerformanceComment.fromJson({'schemaVersion': 3}, id: 'bad'),
      throwsFormatException,
    );
  });
}
