import 'package:cloud_functions/cloud_functions.dart';

typedef AccountDeletionInvoker = Future<Object?> Function();

class ModerationRepository {
  final FirebaseFunctions? _functionsOverride;
  final AccountDeletionInvoker _deleteAccountRequest;

  ModerationRepository({
    FirebaseFunctions? functions,
    AccountDeletionInvoker? accountDeletionInvoker,
  }) : _functionsOverride = functions,
       _deleteAccountRequest =
           accountDeletionInvoker ??
           _firebaseDeleteAccountInvoker(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           );

  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'europe-west2');

  static AccountDeletionInvoker _firebaseDeleteAccountInvoker(
    FirebaseFunctions functions,
  ) {
    return () async {
      final result = await functions.httpsCallable('deleteAccount').call({});
      return result.data;
    };
  }

  Future<void> hideChant(String chantId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'hide',
      'targetId': chantId,
    });
  }

  Future<void> unhideChant(String chantId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'unhide',
      'targetId': chantId,
    });
  }

  Future<void> removeChant(String chantId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'remove',
      'targetId': chantId,
    });
  }

  Future<void> banUser(String userId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'ban',
      'targetId': userId,
    });
  }

  Future<void> unbanUser(String userId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'unban',
      'targetId': userId,
    });
  }

  Future<void> promoteChant(String chantId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'promote',
      'targetId': chantId,
    });
  }

  Future<void> demoteChant(String chantId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'demote',
      'targetId': chantId,
    });
  }

  Future<void> removeChantEvidence(String chantId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'remove-evidence',
      'targetId': chantId,
    });
  }

  Future<void> hideComment(String commentId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'hide-comment',
      'targetId': commentId,
    });
  }

  Future<void> unhideComment(String commentId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'unhide-comment',
      'targetId': commentId,
    });
  }

  Future<void> removeComment(String commentId) async {
    await _functions.httpsCallable('onModerationAction').call({
      'action': 'remove-comment',
      'targetId': commentId,
    });
  }

  Future<void> deleteAccount() async {
    final data = await _deleteAccountRequest();
    if (data is! Map || data['accepted'] != true) {
      throw StateError('Account deletion was not durably accepted.');
    }
  }

  /// Records that the caller accepted the current content policy version.
  /// The server (not the client) decides what "current" means and stamps
  /// the timestamp, so this cannot be forged by a raw client write.
  Future<void> acceptPolicy() async {
    await _functions.httpsCallable('acceptPolicy').call({});
  }

  Future<Map<String, dynamic>> mergeChants({
    required String sourceId,
    required String targetId,
  }) async {
    final result = await _functions.httpsCallable('mergeChants').call({
      'sourceId': sourceId,
      'targetId': targetId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
