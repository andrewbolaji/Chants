import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/presentation/feedback/feedback_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
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
      expect(
          find.text('Tell us what is on your mind.'), findsOneWidget);
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
  });
}
