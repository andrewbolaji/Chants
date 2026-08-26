import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';

class AccountDeletionService {
  final ModerationRepository _moderationRepository;
  final SavedSongbookRepository _savedSongbookRepository;

  const AccountDeletionService({
    required ModerationRepository moderationRepository,
    required SavedSongbookRepository savedSongbookRepository,
  }) : _moderationRepository = moderationRepository,
       _savedSongbookRepository = savedSongbookRepository;

  Future<void> deleteAccount(String uid) {
    return _savedSongbookRepository.runAccountDeletion(
      uid: uid,
      deleteRemoteAccount: _moderationRepository.deleteAccount,
    );
  }
}
