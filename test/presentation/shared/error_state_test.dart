import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/presentation/shared/error_state.dart';

void main() {
  group('ErrorState', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Something went wrong.'),
          ),
        ),
      );
      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, true);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Error'),
          ),
        ),
      );
      expect(find.text('Try again'), findsNothing);
    });
  });
}
