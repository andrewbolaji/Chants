import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/presentation/shared/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyState(message: 'Nothing here yet.')),
        ),
      );
      expect(find.text('Nothing here yet.'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: 'Test',
              icon: Icons.sports_soccer,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });
  });
}
