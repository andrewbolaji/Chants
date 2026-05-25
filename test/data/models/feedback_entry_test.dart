import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/feedback_entry.dart';

void main() {
  group('FeedbackEntry', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'userId': 'user1',
        'category': 'suggestion',
        'message': 'Add more clubs',
        'followUpOk': true,
        'resolved': false,
        'createdAt': Timestamp.fromDate(now),
      };
      final entry = FeedbackEntry.fromJson(json, id: 'fb1');

      expect(entry.id, 'fb1');
      expect(entry.userId, 'user1');
      expect(entry.category, 'suggestion');
      expect(entry.message, 'Add more clubs');
      expect(entry.followUpOk, true);
      expect(entry.resolved, false);

      final output = entry.toJson();
      expect(output['userId'], 'user1');
      expect(output['category'], 'suggestion');
      expect(output.containsKey('id'), false);
    });

    test('valid categories', () {
      expect(FeedbackEntry.validCategories,
          ['suggestion', 'bug', 'question', 'other']);
    });

    test('max message length constant', () {
      expect(FeedbackEntry.maxMessageLength, 1000);
    });
  });
}
