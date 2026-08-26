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
        'banned': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final profile = UserProfile.fromJson(json, id: 'uid1');

      expect(profile.id, 'uid1');
      expect(profile.displayName, 'GoalKing');
      expect(profile.role, 'user');
      expect(profile.banned, false);
      expect(profile.isOperator, false);

      final output = profile.toJson();
      expect(output['displayName'], 'GoalKing');
      expect(output['role'], 'user');
      expect(output['banned'], false);
      expect(output.containsKey('id'), false);
    });

    test('operator role', () {
      final json = {
        'displayName': 'Admin',
        'role': 'operator',
        'banned': false,
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
      expect(updated.banned, false);
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

    test('banned defaults to false', () {
      final json = {
        'displayName': 'Test',
        'role': 'user',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
      };
      final profile = UserProfile.fromJson(json, id: 'uid1');
      expect(profile.banned, false);
    });

    test('banned true reads correctly', () {
      final json = {
        'displayName': 'Banned',
        'role': 'user',
        'banned': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
      };
      final profile = UserProfile.fromJson(json, id: 'uid1');
      expect(profile.banned, true);
    });

    test('toJson includes banned field', () {
      final profile = UserProfile(
        id: 'uid1',
        displayName: 'Test',
        role: 'user',
        banned: true,
        createdAt: DateTime(2026, 5, 24),
        updatedAt: DateTime(2026, 5, 24),
      );
      expect(profile.toJson()['banned'], true);
    });

    test('ageConfirmed17Plus defaults to false and round-trips true', () {
      final now = DateTime(2026, 5, 24);
      final defaultJson = {
        'displayName': 'Test',
        'role': 'user',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      expect(
        UserProfile.fromJson(defaultJson, id: 'uid1').ageConfirmed17Plus,
        false,
      );

      final profile = UserProfile(
        id: 'uid1',
        displayName: 'Test',
        role: 'user',
        ageConfirmed17Plus: true,
        createdAt: now,
        updatedAt: now,
      );
      expect(profile.toJson()['ageConfirmed17Plus'], true);
    });

    test('acceptedPolicyVersion and acceptedPolicyAt default to null and are '
        'absent from toJson (server-set only, never client-written)', () {
      final now = DateTime(2026, 5, 24);
      final json = {
        'displayName': 'Test',
        'role': 'user',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final profile = UserProfile.fromJson(json, id: 'uid1');
      expect(profile.acceptedPolicyVersion, null);
      expect(profile.acceptedPolicyAt, null);

      final output = profile.toJson();
      expect(output.containsKey('acceptedPolicyVersion'), false);
      expect(output.containsKey('acceptedPolicyAt'), false);
    });

    test('acceptedPolicyVersion and acceptedPolicyAt read back correctly '
        'when present', () {
      final now = DateTime(2026, 5, 24);
      final acceptedAt = DateTime(2026, 6, 1);
      final json = {
        'displayName': 'Test',
        'role': 'user',
        'acceptedPolicyVersion': 'v1',
        'acceptedPolicyAt': Timestamp.fromDate(acceptedAt),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final profile = UserProfile.fromJson(json, id: 'uid1');
      expect(profile.acceptedPolicyVersion, 'v1');
      expect(profile.acceptedPolicyAt, acceptedAt);
    });

    test('deletionPending is server-owned, absent-safe, and copyable', () {
      final now = DateTime(2026, 5, 24);
      final base = {
        'displayName': 'Test',
        'role': 'user',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      expect(UserProfile.fromJson(base, id: 'uid1').deletionPending, false);
      final pending = UserProfile.fromJson({
        ...base,
        'deletionPending': true,
      }, id: 'uid1');
      expect(pending.deletionPending, true);
      expect(pending.toJson().containsKey('deletionPending'), false);
      expect(pending.copyWith(displayName: 'Changed').deletionPending, true);
    });

    test('copyWith preserves new fields', () {
      final now = DateTime(2026, 5, 24);
      final profile = UserProfile(
        id: 'uid1',
        displayName: 'Old',
        role: 'user',
        ageConfirmed17Plus: true,
        deletionPending: true,
        acceptedPolicyVersion: 'v1',
        acceptedPolicyAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final updated = profile.copyWith(displayName: 'New');
      expect(updated.ageConfirmed17Plus, true);
      expect(updated.acceptedPolicyVersion, 'v1');
      expect(updated.acceptedPolicyAt, now);
      expect(updated.deletionPending, true);
    });
  });
}
