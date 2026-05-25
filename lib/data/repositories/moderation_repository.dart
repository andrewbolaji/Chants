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
}
