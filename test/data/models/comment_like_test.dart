import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/comment_like.dart';

void main() {
  group('CommentLike', () {
    final now = DateTime(2026, 7, 2, 12, 0, 0);

    test('fromJson and toJson round-trip', () {
      final json = {
        'commentId': 'comment-abc',
        'userId': 'user-123',
        'value': 1,
        'createdAt': Timestamp.fromDate(now),
        'appliedValue': 1,
      };

      final like = CommentLike.fromJson(json, id: 'user-123_comment-abc');

      expect(like.id, 'user-123_comment-abc');
      expect(like.commentId, 'comment-abc');
      expect(like.userId, 'user-123');
      expect(like.value, 1);
      expect(like.createdAt, now);
      expect(like.appliedValue, 1);
    });

    test('toJson omits appliedValue (CF-only field)', () {
      final like = CommentLike(
        id: 'user-123_comment-abc',
        commentId: 'comment-abc',
        userId: 'user-123',
        value: 1,
        createdAt: now,
        appliedValue: 1,
      );

      final out = like.toJson();
      expect(out.containsKey('appliedValue'), false);
      expect(out['commentId'], 'comment-abc');
      expect(out['userId'], 'user-123');
      expect(out['value'], 1);
    });

    test('appliedValue defaults to null when absent', () {
      final json = {
        'commentId': 'comment-abc',
        'userId': 'user-123',
        'value': 1,
        'createdAt': Timestamp.fromDate(now),
      };

      final like = CommentLike.fromJson(json, id: 'user-123_comment-abc');
      expect(like.appliedValue, isNull);
    });

    test('documentId convention matches userId_commentId', () {
      expect(
        CommentLike.documentId('user-123', 'comment-abc'),
        'user-123_comment-abc',
      );
    });
  });
}
