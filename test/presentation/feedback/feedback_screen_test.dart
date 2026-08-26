import 'package:chants/app/providers.dart';
import 'package:chants/data/repositories/safety_submission_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/presentation/feedback/feedback_screen.dart';

class _FakeSafetySubmissionRepository implements SafetySubmissionRepository {
  String? lastCategory;
  String? lastMessage;
  bool? lastFollowUpOk;
  Object? feedbackError;

  @override
  Future<void> submitFeedback({
    required String category,
    required String message,
    required bool followUpOk,
  }) async {
    lastCategory = category;
    lastMessage = message;
    lastFollowUpOk = followUpOk;
    if (feedbackError case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap(Widget child, {SafetySubmissionRepository? repository}) {
    return ProviderScope(
      overrides: [
        if (repository != null)
          safetySubmissionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('FeedbackScreen', () {
    testWidgets('renders category selector', (tester) async {
      await tester.pumpWidget(wrap(const FeedbackScreen()));
      expect(find.text('Suggestion'), findsOneWidget);
      expect(find.text('Bug report'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('renders message field with hint', (tester) async {
      await tester.pumpWidget(wrap(const FeedbackScreen()));
      expect(find.text('Your message'), findsOneWidget);
      expect(find.text('Tell us what is on your mind.'), findsOneWidget);
    });

    testWidgets('renders followUpOk checkbox', (tester) async {
      await tester.pumpWidget(wrap(const FeedbackScreen()));
      expect(find.text('OK to follow up by email'), findsOneWidget);
    });

    testWidgets('submit button disabled when message empty', (tester) async {
      await tester.pumpWidget(wrap(const FeedbackScreen()));
      final sendButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'SEND'),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('shows character count', (tester) async {
      await tester.pumpWidget(wrap(const FeedbackScreen()));
      expect(find.text('0 / 1000'), findsOneWidget);
    });

    testWidgets('submits domain fields without a client identity', (
      tester,
    ) async {
      final repository = _FakeSafetySubmissionRepository();
      await tester.pumpWidget(
        wrap(const FeedbackScreen(), repository: repository),
      );

      await tester.tap(find.text('Bug report'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Playback stopped');
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'SEND'));
      await tester.pump();
      await tester.pump();

      expect(repository.lastCategory, 'bug');
      expect(repository.lastMessage, 'Playback stopped');
      expect(repository.lastFollowUpOk, isTrue);
      expect(find.text('Got it. We read every one.'), findsOneWidget);
    });

    testWidgets('rate-limit failure restores controls and retains the form', (
      tester,
    ) async {
      final repository = _FakeSafetySubmissionRepository()
        ..feedbackError = const SafetySubmissionException(
          SafetySubmissionFailure.rateLimited,
        );
      await tester.pumpWidget(
        wrap(const FeedbackScreen(), repository: repository),
      );

      await tester.tap(find.text('Question'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField),
        'Please keep this message',
      );
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'SEND'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('You have sent several messages recently. Try again later.'),
        findsOneWidget,
      );
      expect(find.text('Please keep this message'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      final sendButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'SEND'),
      );
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('generic failure keeps the existing retry copy', (tester) async {
      final repository = _FakeSafetySubmissionRepository()
        ..feedbackError = Exception('network');
      await tester.pumpWidget(
        wrap(const FeedbackScreen(), repository: repository),
      );

      await tester.enterText(find.byType(TextField), 'Keep this too');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'SEND'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Could not send your feedback. Try again.'),
        findsOneWidget,
      );
      expect(find.text('Keep this too'), findsOneWidget);
    });

  });
}
