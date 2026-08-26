import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/services/account_deletion_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_songbook_storage.dart';

class FakeModerationRepository extends Mock implements ModerationRepository {
  Object? error;
  int calls = 0;

  @override
  Future<void> deleteAccount() async {
    calls += 1;
    if (error != null) throw error!;
  }
}

void main() {
  test('success removes the active UID snapshot and tombstone', () async {
    final storage = MemorySongbookStorage()..active['fan'] = '{broken';
    final moderation = FakeModerationRepository();
    var signOutCalls = 0;
    final service = AccountDeletionService(
      moderationRepository: moderation,
      savedSongbookRepository: SavedSongbookRepository(storage: storage),
      signOut: () async => signOutCalls += 1,
    );

    await service.deleteAccount('fan');

    expect(moderation.calls, 1);
    expect(storage.active, isEmpty);
    expect(storage.tombstones, isEmpty);
    expect(signOutCalls, 1);
  });

  test(
    'remote failure restores exact bytes even when JSON is corrupt',
    () async {
      final storage = MemorySongbookStorage()..active['fan'] = '{broken';
      final moderation = FakeModerationRepository()
        ..error = StateError('callable failed');
      var signOutCalls = 0;
      final service = AccountDeletionService(
        moderationRepository: moderation,
        savedSongbookRepository: SavedSongbookRepository(storage: storage),
        signOut: () async => signOutCalls += 1,
      );

      await expectLater(service.deleteAccount('fan'), throwsStateError);

      expect(storage.active['fan'], '{broken');
      expect(storage.tombstones, isEmpty);
      expect(signOutCalls, 0);
    },
  );

  test('staging failure prevents the remote destructive action', () async {
    final storage = MemorySongbookStorage()
      ..active['fan'] = '{}'
      ..failStage = true;
    final moderation = FakeModerationRepository();
    var signOutCalls = 0;
    final service = AccountDeletionService(
      moderationRepository: moderation,
      savedSongbookRepository: SavedSongbookRepository(storage: storage),
      signOut: () async => signOutCalls += 1,
    );

    await expectLater(service.deleteAccount('fan'), throwsStateError);
    expect(moderation.calls, 0);
    expect(storage.active['fan'], '{}');
    expect(signOutCalls, 0);
  });

  test(
    'accepted deletion signs out when tombstone cleanup is deferred',
    () async {
      final storage = MemorySongbookStorage()
        ..active['fan'] = '{}'
        ..failFinish = true;
      final moderation = FakeModerationRepository();
      var signOutCalls = 0;
      final service = AccountDeletionService(
        moderationRepository: moderation,
        savedSongbookRepository: SavedSongbookRepository(storage: storage),
        signOut: () async => signOutCalls += 1,
      );

      await service.deleteAccount('fan');

      expect(moderation.calls, 1);
      expect(signOutCalls, 1);
      expect(storage.active, isEmpty);
      expect(storage.tombstones['fan'], '{}');

      storage.failFinish = false;
      await storage.cleanupDeletionTombstones();
      expect(storage.tombstones, isEmpty);
    },
  );

  test('sign-out failure never misreports or restores accepted deletion', () async {
    final storage = MemorySongbookStorage()..active['fan'] = '{}';
    final moderation = FakeModerationRepository();
    var signOutCalls = 0;
    final service = AccountDeletionService(
      moderationRepository: moderation,
      savedSongbookRepository: SavedSongbookRepository(storage: storage),
      signOut: () async {
        signOutCalls += 1;
        throw StateError('sign out failed');
      },
    );

    await service.deleteAccount('fan');

    expect(moderation.calls, 1);
    expect(signOutCalls, 1);
    expect(storage.active, isEmpty);
    expect(storage.tombstones, isEmpty);
  });
}
