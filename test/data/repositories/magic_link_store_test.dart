import 'package:chants/data/repositories/magic_link_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MagicLinkStore', () {
    test('round-trips only the pending email, time, and linking UID', () async {
      final preferences = _MemoryPreferences();
      final now = DateTime.utc(2026, 8, 28, 17);
      final store = MagicLinkStore(preferences: preferences, now: () => now);

      await store.save(email: ' fan@example.com ', linkingUid: 'fan');
      final pending = await store.load();

      expect(pending?.email, 'fan@example.com');
      expect(pending?.requestedAt, now);
      expect(pending?.linkingUid, 'fan');
      expect(preferences.values, hasLength(1));
    });

    test('expires old requests and clears every stored field', () async {
      final preferences = _MemoryPreferences();
      var now = DateTime.utc(2026, 8, 28, 17);
      final store = MagicLinkStore(preferences: preferences, now: () => now);
      await store.save(email: 'fan@example.com', linkingUid: 'fan');

      now = now.add(const Duration(hours: 1, seconds: 1));

      expect(await store.load(), isNull);
      expect(preferences.values, isEmpty);
    });

    test(
      'rejects a future timestamp instead of extending the link window',
      () async {
        final preferences = _MemoryPreferences();
        var now = DateTime.utc(2026, 8, 28, 17);
        final store = MagicLinkStore(preferences: preferences, now: () => now);
        await store.save(email: 'fan@example.com');

        now = now.subtract(const Duration(minutes: 1));

        expect(await store.load(), isNull);
        expect(preferences.values, isEmpty);
      },
    );

    test('rejects partial or expanded pending state', () async {
      final preferences = _MemoryPreferences();
      final store = MagicLinkStore(preferences: preferences);
      preferences.values['chants.pendingMagicLink.v1'] =
          '{"schemaVersion":1,"email":"fan@example.com","extra":true}';

      expect(await store.load(), isNull);
      expect(preferences.values, isEmpty);
    });
  });
}
