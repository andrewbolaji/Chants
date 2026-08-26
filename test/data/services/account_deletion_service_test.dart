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
    expect(storage.preparedTombstones, isEmpty);
    expect(storage.unknownTombstones, isEmpty);
    expect(storage.acceptedTombstones, isEmpty);
    expect(signOutCalls, 1);
  });

  test('remote failure preserves exact bytes as an unknown outcome', () async {
    final storage = MemorySongbookStorage()..active['fan'] = '{broken';
    final moderation = FakeModerationRepository()
      ..error = StateError('callable failed');
    var signOutCalls = 0;
    final service = AccountDeletionService(
      moderationRepository: moderation,
      savedSongbookRepository: SavedSongbookRepository(storage: storage),
      signOut: () async => signOutCalls += 1,
    );

    await expectLater(
      service.deleteAccount('fan'),
      throwsA(isA<AccountDeletionRequestUnconfirmedException>()),
    );

    expect(storage.active, isEmpty);
    expect(storage.unknownTombstones['fan'], '{broken');
    expect(signOutCalls, 0);
  });

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
    'request-start failure restores staged data before remote action',
    () async {
      final storage = MemorySongbookStorage()
        ..active['fan'] = '{}'
        ..failStart = true;
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
      expect(storage.preparedTombstones, isEmpty);
      expect(signOutCalls, 0);
    },
  );

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
      expect(storage.acceptedTombstones['fan'], '{}');

      storage.failFinish = false;
      await storage.recoverAccountDeletionArtifacts('fan');
      expect(storage.acceptedTombstones, isEmpty);
    },
  );

  test(
    'sign-out failure never misreports or restores accepted deletion',
    () async {
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
      expect(storage.acceptedTombstones, isEmpty);
    },
  );

  test(
    'retrying an unknown request reuses the tombstone and completes',
    () async {
      final storage = MemorySongbookStorage()..active['fan'] = '{broken';
      final moderation = FakeModerationRepository()
        ..error = StateError('response lost');
      var signOutCalls = 0;
      final service = AccountDeletionService(
        moderationRepository: moderation,
        savedSongbookRepository: SavedSongbookRepository(storage: storage),
        signOut: () async => signOutCalls += 1,
      );

      await expectLater(
        service.deleteAccount('fan'),
        throwsA(isA<AccountDeletionRequestUnconfirmedException>()),
      );
      expect(storage.unknownTombstones['fan'], '{broken');

      moderation.error = null;
      await service.deleteAccount('fan');

      expect(moderation.calls, 2);
      expect(storage.unknownTombstones, isEmpty);
      expect(storage.acceptedTombstones, isEmpty);
      expect(signOutCalls, 1);
    },
  );
}
