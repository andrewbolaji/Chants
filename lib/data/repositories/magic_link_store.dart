import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingMagicLink {
  final String email;
  final DateTime requestedAt;
  final String? linkingUid;

  const PendingMagicLink({
    required this.email,
    required this.requestedAt,
    this.linkingUid,
  });
}

class MagicLinkStore {
  static const _pendingKey = 'chants.pendingMagicLink.v1';
  static const _maxAge = Duration(hours: 1);

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  MagicLinkStore({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _now = now ?? DateTime.now;

  Future<void> save({required String email, String? linkingUid}) async {
    await _preferences.setString(
      _pendingKey,
      jsonEncode({
        'schemaVersion': 1,
        'email': email.trim(),
        'requestedAt': _now().toUtc().toIso8601String(),
        'linkingUid': ?linkingUid,
      }),
    );
  }

  Future<PendingMagicLink?> load() async {
    final rawPending = await _preferences.getString(_pendingKey);
    Object? decoded;
    try {
      decoded = jsonDecode(rawPending ?? '');
    } catch (_) {
      await clear();
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      await clear();
      return null;
    }
    const allowedKeys = {'schemaVersion', 'email', 'requestedAt', 'linkingUid'};
    final linkingUid = decoded['linkingUid'];
    if (decoded['schemaVersion'] != 1 ||
        decoded.keys.length < 3 ||
        decoded.keys.length > 4 ||
        !decoded.keys.every(allowedKeys.contains) ||
        decoded['email'] is! String ||
        (decoded['email'] as String).trim().isEmpty ||
        decoded['requestedAt'] is! String ||
        (linkingUid != null &&
            (linkingUid is! String || linkingUid.trim().isEmpty))) {
      await clear();
      return null;
    }
    final email = decoded['email'] as String;
    final requestedAt = DateTime.tryParse(decoded['requestedAt'] as String);
    if (requestedAt == null) {
      await clear();
      return null;
    }
    final age = _now().toUtc().difference(requestedAt.toUtc());
    if (age.isNegative || age > _maxAge) {
      await clear();
      return null;
    }
    return PendingMagicLink(
      email: email,
      requestedAt: requestedAt,
      linkingUid: linkingUid as String?,
    );
  }

  Future<void> clear() async {
    await _preferences.remove(_pendingKey);
  }
}
