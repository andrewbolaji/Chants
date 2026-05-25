import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'displayName': 'GoalKing',
        'role': 'user',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final profile = UserProfile.fromJson(json, id: 'uid1');

      expect(profile.id, 'uid1');
      expect(profile.displayName, 'GoalKing');
      expect(profile.role, 'user');
      expect(profile.isOperator, false);

      final output = profile.toJson();
      expect(output['displayName'], 'GoalKing');
      expect(output['role'], 'user');
      expect(output.containsKey('id'), false);
    });

    test('operator role', () {
      final json = {
        'displayName': 'Admin',
        'role': 'operator',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
      };
      final profile = UserProfile.fromJson(json, id: 'op1');
      expect(profile.isOperator, true);
    });

    test('valid roles', () {
      expect(UserProfile.validRoles, ['user', 'operator']);
    });

    test('copyWith', () {
      final profile = UserProfile(
        id: 'uid1',
        displayName: 'Old',
        role: 'user',
        createdAt: DateTime(2026, 5, 24),
        updatedAt: DateTime(2026, 5, 24),
      );
      final updated = profile.copyWith(displayName: 'New');
      expect(updated.displayName, 'New');
      expect(updated.role, 'user');
    });

    test('updatedAt field present', () {
      final now = DateTime(2026, 5, 24, 15, 30);
      final profile = UserProfile(
        id: 'uid1',
        displayName: 'Test',
        role: 'user',
        createdAt: now,
        updatedAt: now,
      );
      final json = profile.toJson();
      expect(json.containsKey('updatedAt'), true);
    });
  });
}
