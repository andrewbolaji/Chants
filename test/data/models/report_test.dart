import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/report.dart';

void main() {
  group('Report', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'chantId': 'ch1',
        'reportedBy': 'user1',
        'reason': 'Offensive content',
        'createdAt': Timestamp.fromDate(now),
        'status': 'pending',
      };
      final report = Report.fromJson(json, id: 'r1');

      expect(report.id, 'r1');
      expect(report.chantId, 'ch1');
      expect(report.reportedBy, 'user1');
      expect(report.reason, 'Offensive content');
      expect(report.status, 'pending');

      final output = report.toJson();
      expect(output['chantId'], 'ch1');
      expect(output['status'], 'pending');
      expect(output.containsKey('id'), false);
    });

    test('valid statuses', () {
      expect(Report.validStatuses, ['pending', 'reviewed', 'dismissed']);
    });
  });
}
