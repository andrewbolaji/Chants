import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:chants/data/repositories/chant_update_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFunctionsException extends FirebaseFunctionsException {
  _FakeFunctionsException(String code, {String? reason})
    : super(
        message: 'test failure',
        code: code,
        details: reason == null ? null : {'reason': reason},
      );
}

void main() {
  test(
    'submission payload contains only user-authored domain fields',
    () async {
      String? callable;
      Map<String, Object?>? payload;
      final repository = ChantUpdateRepository(
        invoker: (name, data) async {
          callable = name;
          payload = data;
          return null;
        },
      );

      await repository.submit(
        chantId: 'chant-1',
        kind: ChantUpdateKind.evidence,
        category: null,
        message: 'The whole away end is singing this version.',
        evidence: const ChantEvidence(
          provider: EvidenceProvider.youtube,
          url: 'https://www.youtube.com/watch?v=abcdefghijk',
        ),
      );

      expect(callable, 'submitChantUpdateSuggestion');
      expect(payload, {
        'chantId': 'chant-1',
        'kind': 'evidence',
        'category': null,
        'message': 'The whole away end is singing this version.',
        'evidence': {
          'provider': 'youtube',
          'url': 'https://www.youtube.com/watch?v=abcdefghijk',
        },
      });
      expect(payload!.containsKey('submittedBy'), isFalse);
      expect(payload!.containsKey('status'), isFalse);
      expect(payload!.containsKey('createdAt'), isFalse);
    },
  );

  test('moderation payload does not accept client operator identity', () async {
    Map<String, Object?>? payload;
    final repository = ChantUpdateRepository(
      invoker: (_, data) async {
        payload = data;
        return null;
      },
    );

    await repository.moderate(
      suggestionId: 'suggestion-1',
      action: 'updated',
      resolutionKind: ChantUpdateResolution.variation,
      resolutionNote: 'Added through the reviewed seed path.',
      acknowledgeStale: true,
      acknowledgeEvidenceReplacement: true,
    );

    expect(payload, {
      'suggestionId': 'suggestion-1',
      'action': 'updated',
      'resolutionKind': 'variation',
      'resolutionNote': 'Added through the reviewed seed path.',
      'acknowledgeStale': true,
      'acknowledgeEvidenceReplacement': true,
    });
    expect(payload!.containsKey('actorUid'), isFalse);
    expect(payload!.containsKey('resolvedAt'), isFalse);
  });

  final mappings =
      <({String code, String? reason, ChantUpdateFailure failure})>[
        (
          code: 'already-exists',
          reason: null,
          failure: ChantUpdateFailure.duplicate,
        ),
        (
          code: 'resource-exhausted',
          reason: null,
          failure: ChantUpdateFailure.rateLimited,
        ),
        (
          code: 'failed-precondition',
          reason: 'account-deletion-in-progress',
          failure: ChantUpdateFailure.deletionInProgress,
        ),
        (
          code: 'failed-precondition',
          reason: 'chant-unavailable',
          failure: ChantUpdateFailure.chantUnavailable,
        ),
        (
          code: 'failed-precondition',
          reason: 'stale-chant-version',
          failure: ChantUpdateFailure.stale,
        ),
        (
          code: 'failed-precondition',
          reason: 'evidence-replacement-unconfirmed',
          failure: ChantUpdateFailure.evidenceConflict,
        ),
        (
          code: 'failed-precondition',
          reason: 'review-action-mismatch',
          failure: ChantUpdateFailure.actionMismatch,
        ),
        (
          code: 'failed-precondition',
          reason: 'request-already-closed',
          failure: ChantUpdateFailure.alreadyClosed,
        ),
        (
          code: 'failed-precondition',
          reason: null,
          failure: ChantUpdateFailure.rejected,
        ),
        (
          code: 'permission-denied',
          reason: null,
          failure: ChantUpdateFailure.rejected,
        ),
      ];

  for (final testCase in mappings) {
    test('maps ${testCase.code} to ${testCase.failure.name}', () async {
      final repository = ChantUpdateRepository(
        invoker: (_, _) async => throw _FakeFunctionsException(
          testCase.code,
          reason: testCase.reason,
        ),
      );

      await expectLater(
        repository.submit(
          chantId: 'chant-1',
          kind: ChantUpdateKind.correction,
          category: ChantUpdateCategory.lyrics,
          message: 'The second line needs the away wording.',
          evidence: null,
        ),
        throwsA(
          isA<ChantUpdateException>().having(
            (error) => error.failure,
            'failure',
            testCase.failure,
          ),
        ),
      );
    });
  }

  test('isolates malformed and future suggestion rows', () {
    final timestamp = Timestamp.fromMillisecondsSinceEpoch(1000);
    final valid = <String, dynamic>{
      'schemaVersion': 1,
      'chantId': 'chant-1',
      'chantTitleSnapshot': 'North Bank Song',
      'submittedBy': 'supporter',
      'kind': 'correction',
      'category': 'lyrics',
      'message': 'The second line needs the away wording.',
      'evidence': null,
      'chantUpdatedAt': timestamp,
      'status': 'received',
      'resolutionKind': null,
      'resolutionNote': null,
      'createdAt': timestamp,
      'updatedAt': timestamp,
      'resolvedAt': null,
    };

    expect(ChantUpdateSuggestion.tryFromJson(valid, id: 'valid'), isNotNull);
    expect(
      ChantUpdateSuggestion.tryFromJson({
        ...valid,
        'schemaVersion': 2,
      }, id: 'future'),
      isNull,
    );
    expect(
      ChantUpdateSuggestion.tryFromJson({
        ...valid,
        'chantUpdatedAt': 'bad',
      }, id: 'malformed'),
      isNull,
    );
  });
}
