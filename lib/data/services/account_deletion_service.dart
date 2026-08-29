import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';

class AccountDeletionService {
  final ModerationRepository _moderationRepository;
  final SavedSongbookRepository _savedSongbookRepository;
  final Future<void> Function() _signOut;

  const AccountDeletionService({
    required ModerationRepository moderationRepository,
    required SavedSongbookRepository savedSongbookRepository,
    required Future<void> Function() signOut,
  }) : // Keep public dependency names readable outside this library.
       // ignore: prefer_initializing_formals
       _moderationRepository = moderationRepository,
       // ignore: prefer_initializing_formals
       _savedSongbookRepository = savedSongbookRepository,
       // ignore: prefer_initializing_formals
       _signOut = signOut;

  Future<void> deleteAccount(String uid) async {
    await _savedSongbookRepository.runAccountDeletion(
      uid: uid,
      deleteRemoteAccount: _moderationRepository.deleteAccount,
    );
    try {
      await _signOut();
    } catch (_) {
      // Remote deletion is already durable and local data is unreadable.
      // The pending-profile app gate is the recovery surface for a session
      // that could not complete this best-effort sign-out.
    }
  }
}
