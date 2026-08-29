import 'package:cloud_functions/cloud_functions.dart';

typedef CompleteOnboardingInvoker =
    Future<Object?> Function(Map<String, Object> payload);

class OnboardingRepository {
  final CompleteOnboardingInvoker _invoke;

  OnboardingRepository({
    FirebaseFunctions? functions,
    CompleteOnboardingInvoker? invoker,
  }) : _invoke =
           invoker ??
           _firebaseInvoker(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           );

  static CompleteOnboardingInvoker _firebaseInvoker(
    FirebaseFunctions functions,
  ) {
    return (payload) async {
      final result = await functions
          .httpsCallable('completeOnboarding')
          .call(payload);
      return result.data;
    };
  }

  Future<void> complete({required String displayName}) async {
    final result = await _invoke({
      'displayName': displayName.trim(),
      'ageConfirmed17Plus': true,
      'policyAccepted': true,
    });
    if (result is! Map || result['completed'] != true) {
      throw StateError('Onboarding was not completed.');
    }
  }
}
