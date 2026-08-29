import 'package:chants/app/providers.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/data/repositories/onboarding_repository.dart';
import 'package:chants/presentation/auth/onboarding_screen.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _ValidationOnlyAuthRepository extends Mock implements AuthRepository {
  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    throw StateError('Network boundary is not used by validation assertions.');
  }
}

class _FakeOnboardingRepository extends Mock implements OnboardingRepository {
  int calls = 0;
  String? displayName;
  final displayNames = <String>[];

  @override
  Future<void> complete({required String displayName}) async {
    calls += 1;
    this.displayName = displayName;
    displayNames.add(displayName);
  }
}

void main() {
  Widget wrap(Widget child, {_FakeOnboardingRepository? onboarding}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _ValidationOnlyAuthRepository(),
        ),
        if (onboarding != null)
          onboardingRepositoryProvider.overrideWithValue(onboarding),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('SignUpScreen email credential validation', () {
    Future<void> fill(
      WidgetTester tester, {
      String password = 'password123',
      String confirmation = 'password123',
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        password,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        confirmation,
      );
    }

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fill(tester, confirmation: 'differentpassword');

      await tester.tap(find.widgetWithText(FilledButton, 'CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('matching valid passwords clear local validation', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fill(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsNothing);
    });

    testWidgets('requires eight password characters', (tester) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await fill(tester, password: 'short', confirmation: 'short');

      await tester.tap(find.widgetWithText(FilledButton, 'CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('At least 8 characters.'), findsNWidgets(2));
    });

    testWidgets('both password fields have visibility controls', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    });
  });

  group('OnboardingScreen age and policy admission', () {
    Future<void> pickDateOfBirth(WidgetTester tester, int yearsAgo) async {
      await tester.tap(find.text('Tap to choose'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final dob = DateTime(now.year - yearsAgo, now.month, now.day);
      final formatted =
          '${dob.month.toString().padLeft(2, '0')}/'
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

    testWidgets('blocks completion with no date of birth', (tester) async {
      await tester.pumpWidget(
        wrap(OnboardingScreen(onDestinationSelected: (_) {})),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Testuser',
      );

      await tester.tap(find.text('ENTER CHANTS'));
      await tester.pump();

      expect(find.text('Add your date of birth.'), findsOneWidget);
    });

    testWidgets('shows the under-17 boundary and does not allow entry', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(OnboardingScreen(onDestinationSelected: (_) {})),
      );
      await pickDateOfBirth(tester, 10);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('17 or older'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'ENTER CHANTS'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('blocks completion until policy is accepted', (tester) async {
      await tester.pumpWidget(
        wrap(OnboardingScreen(onDestinationSelected: (_) {})),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Testuser',
      );
      await pickDateOfBirth(tester, 20);

      await tester.tap(find.text('ENTER CHANTS'));
      await tester.pump();

      expect(
        find.text('Agree to the Content Policy to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('adult consent completes once and retains first destination', (
      tester,
    ) async {
      final onboarding = _FakeOnboardingRepository();
      var destination = -1;
      await tester.pumpWidget(
        wrap(
          OnboardingScreen(
            onDestinationSelected: (value) => destination = value,
          ),
          onboarding: onboarding,
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        ' Testuser ',
      );
      await pickDateOfBirth(tester, 20);
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Songbook'));
      await tester.tap(find.text('ENTER CHANTS'));
      await tester.pump();

      expect(onboarding.calls, 1);
      expect(onboarding.displayName, ' Testuser ');
      expect(destination, 3);
    });

    testWidgets(
      'successful setup freezes saved fields and keeps truthful recovery',
      (tester) async {
        final onboarding = _FakeOnboardingRepository();
        await tester.pumpWidget(
          wrap(
            OnboardingScreen(onDestinationSelected: (_) {}),
            onboarding: onboarding,
          ),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Display name'),
          'Testuser',
        );
        await pickDateOfBirth(tester, 20);
        await tester.tap(find.byType(Checkbox));
        await tester.tap(find.text('ENTER CHANTS'));
        await tester.pump();

        expect(find.textContaining('Setup is saved'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('CHECK AGAIN'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('ENTER CHANTS'), findsNothing);
        final displayNameField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Display name'),
        );
        expect(displayNameField.enabled, isFalse);
        expect(displayNameField.controller?.text, 'Testuser');
        expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile))
              .onChanged,
          isNull,
        );
        expect(
          tester
              .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
              .onSelectionChanged,
          isNull,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'CHECK AGAIN'),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'SIGN OUT'))
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.text('CHECK AGAIN'));
        await tester.pump();

        expect(onboarding.calls, 2);
        expect(onboarding.displayNames, ['Testuser', 'Testuser']);
        expect(find.textContaining('Setup is saved'), findsOneWidget);
      },
    );

    testWidgets('destination selector has a 48-pixel minimum target', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(OnboardingScreen(onDestinationSelected: (_) {})),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(SegmentedButton<int>)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
