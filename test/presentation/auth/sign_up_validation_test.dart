import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('SignUpScreen password confirm', () {
    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));

      // Fill in display name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Testuser',
      );

      // Fill in email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      // Fill in password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Fill in confirm password with mismatch
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'differentpassword',
      );

      // Tap create account
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('no error when passwords match', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'password123',
      );

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsNothing);
    });

    testWidgets('show-password toggle exists', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));

      // Should find visibility toggle icons (two password fields)
      expect(
        find.byIcon(Icons.visibility_off_outlined),
        findsNWidgets(2),
      );
    });
  });
}
