import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/services/age.dart';

void main() {
  group('calculateAge', () {
    test('birthday already passed this year', () {
      final dob = DateTime(2000, 1, 15);
      final now = DateTime(2026, 6, 1);
      expect(calculateAge(dob, now), 26);
    });

    test('birthday later this year, not reached yet', () {
      final dob = DateTime(2000, 12, 15);
      final now = DateTime(2026, 6, 1);
      expect(calculateAge(dob, now), 25);
    });

    test('birthday is today', () {
      final dob = DateTime(2000, 6, 1);
      final now = DateTime(2026, 6, 1);
      expect(calculateAge(dob, now), 26);
    });

    test('exactly kMinimumAge years old today counts as old enough', () {
      final dob = DateTime(2009, 6, 1);
      final now = DateTime(2026, 6, 1);
      expect(calculateAge(dob, now), kMinimumAge);
    });

    test('one day short of kMinimumAge is under the limit', () {
      final dob = DateTime(2009, 6, 2);
      final now = DateTime(2026, 6, 1);
      expect(calculateAge(dob, now), kMinimumAge - 1);
    });

    test('kMinimumAge is 17', () {
      expect(kMinimumAge, 17);
    });
  });
}
