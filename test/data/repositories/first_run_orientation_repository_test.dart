import 'package:chants/data/repositories/first_run_orientation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, bool>{};

  @override
  Future<bool?> getBool(String key) async => values[key];

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirstRunOrientationRepository', () {
    test('defaults to incomplete without writing device state', () async {
      final preferences = _MemoryPreferences();
      final repository = FirstRunOrientationRepository(
        preferences: preferences,
      );

      expect(await repository.isComplete(), isFalse);
      expect(preferences.values, isEmpty);
    });

    test('records only the versioned completion flag', () async {
      final preferences = _MemoryPreferences();
      final repository = FirstRunOrientationRepository(
        preferences: preferences,
      );

      await repository.markComplete();

      expect(await repository.isComplete(), isTrue);
      expect(preferences.values, {
        FirstRunOrientationRepository.completedKey: true,
      });
    });
  });
}
