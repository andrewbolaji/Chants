import 'package:cloud_functions/cloud_functions.dart';

enum SafetyReportTargetType { chant, comment, user }

enum SafetySubmissionFailure { duplicate, rateLimited, rejected }

class SafetySubmissionException implements Exception {
  final SafetySubmissionFailure failure;

  const SafetySubmissionException(this.failure);
}

typedef SafetyCallableInvoker =
    Future<void> Function(String callableName, Map<String, Object> payload);

class SafetySubmissionRepository {
  final SafetyCallableInvoker _invoke;

  SafetySubmissionRepository({
    FirebaseFunctions? functions,
    SafetyCallableInvoker? invoker,
  }) : _invoke =
           invoker ??
           _firebaseInvoker(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           );

  static SafetyCallableInvoker _firebaseInvoker(FirebaseFunctions functions) {
    return (callableName, payload) async {
      await functions.httpsCallable(callableName).call(payload);
    };
  }

  Future<void> submitReport({
    required SafetyReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    await _call('submitReport', {
      'targetType': targetType.name,
      'targetId': targetId,
      'reason': reason,
    });
  }

  Future<void> submitFeedback({
    required String category,
    required String message,
    required bool followUpOk,
  }) async {
    await _call('submitFeedback', {
      'category': category,
      'message': message,
      'followUpOk': followUpOk,
    });
  }

  Future<void> _call(String callableName, Map<String, Object> payload) async {
    try {
      await _invoke(callableName, payload);
    } on FirebaseFunctionsException catch (error) {
      final failure = switch (error.code) {
        'already-exists' => SafetySubmissionFailure.duplicate,
        'resource-exhausted' => SafetySubmissionFailure.rateLimited,
        _ => SafetySubmissionFailure.rejected,
      };
      throw SafetySubmissionException(failure);
    } on SafetySubmissionException {
      rethrow;
    } catch (_) {
      throw const SafetySubmissionException(SafetySubmissionFailure.rejected);
    }
  }
}
