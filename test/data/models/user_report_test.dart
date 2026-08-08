import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/user_report.dart';

void main() {
  group('UserReport', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'reportedUserId': 'user2',
        'reportedBy': 'user1',
        'reason': 'Hate speech or slurs',
        'createdAt': Timestamp.fromDate(now),
        'status': 'pending',
      };
      final report = UserReport.fromJson(json, id: 'r1');

      expect(report.id, 'r1');
      expect(report.reportedUserId, 'user2');
      expect(report.reportedBy, 'user1');
      expect(report.reason, 'Hate speech or slurs');
      expect(report.status, 'pending');

      final output = report.toJson();
      expect(output['reportedUserId'], 'user2');
      expect(output['status'], 'pending');
      expect(output.containsKey('id'), false);
    });

    test('valid statuses', () {
      expect(UserReport.validStatuses, ['pending', 'reviewed', 'dismissed']);
    });
  });
}
