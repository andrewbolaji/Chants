import 'package:chants/data/repositories/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingRepository', () {
    test('sends the exact server-confirmed profile payload', () async {
      Map<String, Object>? captured;
      final repository = OnboardingRepository(
        invoker: (payload) async {
          captured = payload;
          return {'completed': true};
        },
      );

      await repository.complete(displayName: ' Terrace Fan ');

      expect(captured, {
        'displayName': 'Terrace Fan',
        'ageConfirmed17Plus': true,
        'policyAccepted': true,
      });
    });

    test(
      'fails closed when the callable does not confirm completion',
      () async {
        final repository = OnboardingRepository(
          invoker: (_) async => {'completed': false},
        );

        await expectLater(
          repository.complete(displayName: 'Terrace Fan'),
          throwsStateError,
        );
      },
    );
  });
}
