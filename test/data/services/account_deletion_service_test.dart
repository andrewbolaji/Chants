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
    final service = AccountDeletionService(
      moderationRepository: moderation,
      savedSongbookRepository: SavedSongbookRepository(storage: storage),
    );

    await service.deleteAccount('fan');

    expect(moderation.calls, 1);
    expect(storage.active, isEmpty);
    expect(storage.tombstones, isEmpty);
  });

  test(
    'remote failure restores exact bytes even when JSON is corrupt',
    () async {
      final storage = MemorySongbookStorage()..active['fan'] = '{broken';
      final moderation = FakeModerationRepository()
        ..error = StateError('callable failed');
      final service = AccountDeletionService(
        moderationRepository: moderation,
        savedSongbookRepository: SavedSongbookRepository(storage: storage),
      );

      await expectLater(service.deleteAccount('fan'), throwsStateError);

      expect(storage.active['fan'], '{broken');
      expect(storage.tombstones, isEmpty);
    },
  );

  test('staging failure prevents the remote destructive action', () async {
    final storage = MemorySongbookStorage()
      ..active['fan'] = '{}'
      ..failStage = true;
    final moderation = FakeModerationRepository();
    final service = AccountDeletionService(
      moderationRepository: moderation,
      savedSongbookRepository: SavedSongbookRepository(storage: storage),
    );

    await expectLater(service.deleteAccount('fan'), throwsStateError);
    expect(moderation.calls, 0);
    expect(storage.active['fan'], '{}');
  });
}
