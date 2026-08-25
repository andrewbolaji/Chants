import 'package:chants/data/repositories/safety_submission_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFunctionsException extends FirebaseFunctionsException {
  _FakeFunctionsException(String code)
    : super(message: 'test failure', code: code);
}

void main() {
  group('SafetySubmissionRepository', () {
    test('report payload contains domain fields only', () async {
      String? callable;
      Map<String, Object>? payload;
      final repository = SafetySubmissionRepository(
        invoker: (name, data) async {
          callable = name;
          payload = data;
        },
      );

      await repository.submitReport(
        targetType: SafetyReportTargetType.comment,
        targetId: 'comment-1',
        reason: 'Something else: context',
      );

      expect(callable, 'submitReport');
      expect(payload, {
        'targetType': 'comment',
        'targetId': 'comment-1',
        'reason': 'Something else: context',
      });
      expect(payload!.containsKey('reportedBy'), isFalse);
      expect(payload!.containsKey('createdAt'), isFalse);
      expect(payload!.containsKey('status'), isFalse);
    });

    test('feedback payload contains domain fields only', () async {
      String? callable;
      Map<String, Object>? payload;
      final repository = SafetySubmissionRepository(
        invoker: (name, data) async {
          callable = name;
          payload = data;
        },
      );

      await repository.submitFeedback(
        category: 'suggestion',
        message: 'Add a stadium mode',
        followUpOk: true,
      );

      expect(callable, 'submitFeedback');
      expect(payload, {
        'category': 'suggestion',
        'message': 'Add a stadium mode',
        'followUpOk': true,
      });
      expect(payload!.containsKey('userId'), isFalse);
      expect(payload!.containsKey('createdAt'), isFalse);
      expect(payload!.containsKey('resolved'), isFalse);
    });

    final mappings = <({String code, SafetySubmissionFailure failure})>[
      (code: 'already-exists', failure: SafetySubmissionFailure.duplicate),
      (
        code: 'resource-exhausted',
        failure: SafetySubmissionFailure.rateLimited,
      ),
      (code: 'permission-denied', failure: SafetySubmissionFailure.rejected),
    ];

    for (final testCase in mappings) {
      test('maps ${testCase.code} to ${testCase.failure.name}', () async {
        final repository = SafetySubmissionRepository(
          invoker: (_, _) async =>
              throw _FakeFunctionsException(testCase.code),
        );

        await expectLater(
          repository.submitReport(
            targetType: SafetyReportTargetType.chant,
            targetId: 'chant-1',
            reason: 'reason',
          ),
          throwsA(
            isA<SafetySubmissionException>().having(
              (error) => error.failure,
              'failure',
              testCase.failure,
            ),
          ),
        );
      });
    }

    test('maps non-callable failures to rejected', () async {
      final repository = SafetySubmissionRepository(
        invoker: (_, _) async => throw Exception('network'),
      );

      await expectLater(
        repository.submitFeedback(
          category: 'other',
          message: 'hello',
          followUpOk: false,
        ),
        throwsA(
          isA<SafetySubmissionException>().having(
            (error) => error.failure,
            'failure',
            SafetySubmissionFailure.rejected,
          ),
        ),
      );
    });
  });
}
