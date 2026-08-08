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

  group('SignUpScreen policy and age gate', () {
    Future<void> fillBaseFields(WidgetTester tester) async {
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
    }

    /// Drives the real Material date picker (input mode) to set a date of
    /// birth [yearsAgo] years before today.
    Future<void> pickDateOfBirth(WidgetTester tester, int yearsAgo) async {
      await tester.tap(find.text('Tap to choose'));
      await tester.pumpAndSettle();

      // Switch the calendar picker to text-entry mode.
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final dob = DateTime(now.year - yearsAgo, now.month, now.day);
      final formatted = '${dob.month.toString().padLeft(2, '0')}/'
          '${dob.day.toString().padLeft(2, '0')}/${dob.year}';

      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        formatted,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('blocks submit with no date of birth', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fillBaseFields(tester);

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Add your date of birth.'), findsOneWidget);
    });

    testWidgets('blocks submit for a date of birth under 17', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fillBaseFields(tester);
      await pickDateOfBirth(tester, 10);

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.textContaining('17 or older'), findsOneWidget);
    });

    testWidgets('blocks submit when the policy checkbox is unchecked',
        (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fillBaseFields(tester);
      await pickDateOfBirth(tester, 20);

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(
        find.text('Agree to the Content Policy to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('picking a date of birth replaces the placeholder text',
        (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));

      expect(find.text('Tap to choose'), findsOneWidget);
      await pickDateOfBirth(tester, 20);
      expect(find.text('Tap to choose'), findsNothing);
    });

    testWidgets(
        'an adult date of birth plus the checkbox clears both blocking '
        'errors, only the network call fails in this offline test',
        (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fillBaseFields(tester);
      await pickDateOfBirth(tester, 20);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Add your date of birth.'), findsNothing);
      expect(find.textContaining('17 or older'), findsNothing);
      expect(
        find.text('Agree to the Content Policy to continue.'),
        findsNothing,
      );
    });
  });
}
