import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModerationRepository account deletion', () {
    test('accepts only the explicit durable response', () async {
      final repository = ModerationRepository(
        accountDeletionInvoker: () async => {'accepted': true, 'success': true},
      );

      await repository.deleteAccount();
    });

    for (final response in <Object?>[
      null,
      true,
      <String, Object?>{},
      {'success': true},
      {'accepted': false, 'success': true},
    ]) {
      test('rejects non-durable response $response', () async {
        final repository = ModerationRepository(
          accountDeletionInvoker: () async => response,
        );

        await expectLater(repository.deleteAccount(), throwsStateError);
      });
    }
  });
}
