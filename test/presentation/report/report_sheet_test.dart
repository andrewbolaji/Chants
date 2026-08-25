import 'package:chants/app/providers.dart';
import 'package:chants/data/repositories/safety_submission_repository.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSafetySubmissionRepository implements SafetySubmissionRepository {
  SafetyReportTargetType? lastTargetType;
  String? lastTargetId;
  String? lastReason;
  Object? reportError;

  @override
  Future<void> submitReport({
    required SafetyReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    lastTargetType = targetType;
    lastTargetId = targetId;
    lastReason = reason;
    if (reportError case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpReportSheet(
  WidgetTester tester, {
  required ReportTarget target,
  required SafetySubmissionRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        safetySubmissionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: FilledButton(
              onPressed: () =>
                  showReportSheet(context: context, target: target, ref: ref),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _chooseAndSubmit(
  WidgetTester tester, {
  required String category,
  required String buttonLabel,
  String? note,
}) async {
  await tester.tap(find.text(category));
  await tester.pump();
  if (note != null) {
    await tester.enterText(find.byType(TextField), note);
  }
  await tester.tap(find.widgetWithText(FilledButton, buttonLabel));
  await tester.pump();
  await tester.pump();
}

void main() {
  group('showReportSheet', () {
    final targets =
        <
          ({
            ReportTarget target,
            String title,
            SafetyReportTargetType type,
            String id,
          })
        >[
          (
            target: const ReportChant('chant-1'),
            title: 'Report this chant',
            type: SafetyReportTargetType.chant,
            id: 'chant-1',
          ),
          (
            target: const ReportComment('comment-1'),
            title: 'Report this comment',
            type: SafetyReportTargetType.comment,
            id: 'comment-1',
          ),
          (
            target: const ReportUser('bad-actor-1'),
            title: 'Report this user',
            type: SafetyReportTargetType.user,
            id: 'bad-actor-1',
          ),
        ];

    for (final testCase in targets) {
      testWidgets('submits ${testCase.type.name} through the safety boundary', (
        tester,
      ) async {
        final repository = _FakeSafetySubmissionRepository();
        await _pumpReportSheet(
          tester,
          target: testCase.target,
          repository: repository,
        );

        await _chooseAndSubmit(
          tester,
          category: 'Hate speech or slurs',
          buttonLabel: testCase.title,
          note: 'extra context',
        );

        expect(repository.lastTargetType, testCase.type);
        expect(repository.lastTargetId, testCase.id);
        expect(repository.lastReason, 'Hate speech or slurs: extra context');
        expect(find.text('Got it. We will take a look.'), findsOneWidget);
      });
    }

    final failures = <({Object error, String copy})>[
      (
        error: const SafetySubmissionException(
          SafetySubmissionFailure.duplicate,
        ),
        copy: 'You already reported this.',
      ),
      (
        error: const SafetySubmissionException(
          SafetySubmissionFailure.rateLimited,
        ),
        copy: 'You have sent several reports recently. Try again later.',
      ),
      (
        error: Exception('network'),
        copy: 'Could not send your report. Try again.',
      ),
    ];

    for (final testCase in failures) {
      testWidgets('shows ${testCase.copy} and retains entered report work', (
        tester,
      ) async {
        final repository = _FakeSafetySubmissionRepository()
          ..reportError = testCase.error;
        await _pumpReportSheet(
          tester,
          target: const ReportChant('chant-1'),
          repository: repository,
        );

        await _chooseAndSubmit(
          tester,
          category: 'Something else',
          buttonLabel: 'Report this chant',
          note: 'Please keep this note',
        );

        expect(find.text(testCase.copy), findsOneWidget);
        expect(find.text('Please keep this note'), findsOneWidget);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Report this chant'),
        );
        expect(button.onPressed, isNotNull);
      });
    }

  });
}
