import 'package:cloud_functions/cloud_functions.dart';

class ModerationRepository {
  final FirebaseFunctions _functions;

  ModerationRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2');

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
    await _functions.httpsCallable('deleteAccount').call({});
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
