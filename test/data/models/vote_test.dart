import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/vote.dart';

void main() {
  group('Vote', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'chantId': 'ch1',
        'userId': 'user1',
        'value': 1,
        'createdAt': Timestamp.fromDate(now),
      };
      final vote = Vote.fromJson(json, id: 'user1_ch1');

      expect(vote.id, 'user1_ch1');
      expect(vote.chantId, 'ch1');
      expect(vote.userId, 'user1');
      expect(vote.value, 1);

      final output = vote.toJson();
      expect(output['chantId'], 'ch1');
      expect(output['value'], 1);
      expect(output.containsKey('id'), false);
    });

    test('documentId convention', () {
      expect(Vote.documentId('user1', 'ch1'), 'user1_ch1');
      expect(Vote.documentId('abc', 'def'), 'abc_def');
    });

    test('downvote value', () {
      final json = {
        'chantId': 'ch1',
        'userId': 'user1',
        'value': -1,
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
      };
      final vote = Vote.fromJson(json, id: 'user1_ch1');
      expect(vote.value, -1);
    });
  });
}
