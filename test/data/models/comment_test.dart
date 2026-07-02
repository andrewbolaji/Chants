import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/comment.dart';

void main() {
  group('Comment', () {
    final now = DateTime(2026, 7, 2, 12, 0, 0);

    test('fromJson and toJson round-trip', () {
      final json = {
        'chantId': 'chant-abc',
        'userId': 'user-123',
        'displayName': 'Test User',
        'body': 'Test comment body',
        'createdAt': Timestamp.fromDate(now),
        'likeCount': 5,
        'flagCount': 1,
        'hidden': false,
        'removed': false,
      };

      final comment = Comment.fromJson(json, id: 'comment-1');

      expect(comment.id, 'comment-1');
      expect(comment.chantId, 'chant-abc');
      expect(comment.userId, 'user-123');
      expect(comment.displayName, 'Test User');
      expect(comment.body, 'Test comment body');
      expect(comment.createdAt, now);
      expect(comment.likeCount, 5);
      expect(comment.flagCount, 1);
      expect(comment.hidden, false);
      expect(comment.removed, false);

      final out = comment.toJson();
      expect(out['chantId'], 'chant-abc');
      expect(out['userId'], 'user-123');
      expect(out['displayName'], 'Test User');
      expect(out['body'], 'Test comment body');
      expect(out['likeCount'], 5);
      expect(out['flagCount'], 1);
      expect(out['hidden'], false);
      expect(out['removed'], false);
    });

    test('counters and flags default to safe values', () {
      final json = {
        'chantId': 'chant-abc',
        'userId': 'user-123',
        'displayName': 'Test User',
        'body': 'Minimal comment',
        'createdAt': Timestamp.fromDate(now),
      };

      final comment = Comment.fromJson(json, id: 'comment-2');

      expect(comment.likeCount, 0);
      expect(comment.flagCount, 0);
      expect(comment.hidden, false);
      expect(comment.removed, false);
    });
  });
}
