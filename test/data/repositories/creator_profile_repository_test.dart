import 'package:chants/data/repositories/creator_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identity update sends only the approved public fields', () async {
    Map<String, Object>? received;
    final repository = CreatorProfileRepository(
      invoker: (payload) async => received = payload,
    );

    await repository.updateIdentity(
      displayName: 'North Bank Leo',
      handle: 'northbankleo',
      bio: 'Arsenal and away ends.',
    );

    expect(received, {
      'displayName': 'North Bank Leo',
      'handle': 'northbankleo',
      'bio': 'Arsenal and away ends.',
    });
  });

  test(
    'unknown callable failure becomes a stable unavailable failure',
    () async {
      final repository = CreatorProfileRepository(
        invoker: (_) async => throw StateError('network details'),
      );

      await expectLater(
        repository.updateIdentity(
          displayName: 'Fan',
          handle: 'valid_fan',
          bio: '',
        ),
        throwsA(
          isA<CreatorProfileException>().having(
            (error) => error.failure,
            'failure',
            CreatorProfileFailure.unavailable,
          ),
        ),
      );
    },
  );

  test('domain failures are preserved for the form to explain', () async {
    final repository = CreatorProfileRepository(
      invoker: (_) async => throw const CreatorProfileException(
        CreatorProfileFailure.handleUnavailable,
      ),
    );

    await expectLater(
      repository.updateIdentity(displayName: 'Fan', handle: 'taken', bio: ''),
      throwsA(
        isA<CreatorProfileException>().having(
          (error) => error.failure,
          'failure',
          CreatorProfileFailure.handleUnavailable,
        ),
      ),
    );
  });
}
