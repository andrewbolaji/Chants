import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/audit_log_entry.dart';

void main() {
  group('AuditLogEntry', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'actorId': 'op1',
        'action': 'remove',
        'targetType': 'chant',
        'targetId': 'ch1',
        'detail': 'Removed for policy violation',
        'createdAt': Timestamp.fromDate(now),
      };
      final entry = AuditLogEntry.fromJson(json, id: 'log1');

      expect(entry.id, 'log1');
      expect(entry.actorId, 'op1');
      expect(entry.action, 'remove');
      expect(entry.targetType, 'chant');
      expect(entry.targetId, 'ch1');

      final output = entry.toJson();
      expect(output['actorId'], 'op1');
      expect(output['action'], 'remove');
      expect(output.containsKey('id'), false);
    });
  });
}
