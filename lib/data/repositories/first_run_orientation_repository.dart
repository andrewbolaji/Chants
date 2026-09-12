import 'package:shared_preferences/shared_preferences.dart';

/// Device-local completion state for the short V1 product orientation.
///
/// This contains no account or behavioral data. The versioned key lets a
/// future guide use a different flag without silently replaying this one.
class FirstRunOrientationRepository {
  static const completedKey = 'chants.firstRunOrientation.completed.v1';

  final SharedPreferencesAsync _preferences;

  FirstRunOrientationRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<bool> isComplete() async {
    return await _preferences.getBool(completedKey) ?? false;
  }

  Future<void> markComplete() async {
    await _preferences.setBool(completedKey, true);
  }
}
