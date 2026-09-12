import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
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

class _SuccessfulAuthRepository extends Mock implements AuthRepository {
  int signUpCalls = 0;
  int verificationCalls = 0;

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    return _TestUserCredential();
  }

  @override
  Future<bool> sendEmailVerification() async {
    verificationCalls += 1;
    return true;
  }
}

class _TestUserCredential extends Mock implements UserCredential {}

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
  Widget wrap(
    Widget child, {
    _FakeOnboardingRepository? onboarding,
    AuthRepository? auth,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          auth ?? _ValidationOnlyAuthRepository(),
        ),
        if (onboarding != null)
          onboardingRepositoryProvider.overrideWithValue(onboarding),
      ],
      child: MaterialApp(theme: ChantTheme.dark, home: child),
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

    testWidgets('successful signup exits the loading route for app gating', (
      tester,
    ) async {
      final repository = _SuccessfulAuthRepository();
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('OPEN SIGNUP'),
              ),
            ),
          ),
          auth: repository,
        ),
      );
      await tester.tap(find.text('OPEN SIGNUP'));
      await tester.pumpAndSettle();
      await fill(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(repository.signUpCalls, 1);
      expect(repository.verificationCalls, 1);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.text('OPEN SIGNUP'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('OnboardingScreen age and policy admission', () {
    Future<void> scrollTo(WidgetTester tester, Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }

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
        find.byKey(const Key('onboarding-display-name-field')),
        'Testuser',
      );

      await scrollTo(tester, find.text('ENTER CHANTS'));
      await tester.tap(find.text('ENTER CHANTS'));
      await tester.pump();

      expect(find.text('Add your date of birth.'), findsOneWidget);
    });

    testWidgets('clears the missing display-name error while correcting it', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(OnboardingScreen(onDestinationSelected: (_) {})),
      );

      await scrollTo(tester, find.text('ENTER CHANTS'));
      await tester.tap(find.text('ENTER CHANTS'));
      await tester.pump();
      expect(find.text('Pick a display name.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('onboarding-display-name-field')),
        'Testuser',
      );
      await tester.pump();

      expect(find.text('Pick a display name.'), findsNothing);
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
        find.byKey(const Key('onboarding-display-name-field')),
        'Testuser',
      );
      await pickDateOfBirth(tester, 20);

      await scrollTo(tester, find.text('ENTER CHANTS'));
      await tester.tap(find.text('ENTER CHANTS'));
      await tester.pump();

      expect(
        find.text('Agree to the Terms and Community Rules to continue.'),
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
        find.byKey(const Key('onboarding-display-name-field')),
        ' Testuser ',
      );
      await pickDateOfBirth(tester, 20);
      await scrollTo(tester, find.byKey(const Key('onboarding-policy-toggle')));
      await tester.tap(find.byKey(const Key('onboarding-policy-toggle')));
      await tester.tap(find.text('Songbook'));
      await scrollTo(tester, find.text('ENTER CHANTS'));
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
          find.byKey(const Key('onboarding-display-name-field')),
          'Testuser',
        );
        await pickDateOfBirth(tester, 20);
        await scrollTo(
          tester,
          find.byKey(const Key('onboarding-policy-toggle')),
        );
        await tester.tap(find.byKey(const Key('onboarding-policy-toggle')));
        await scrollTo(tester, find.text('ENTER CHANTS'));
        await tester.tap(find.text('ENTER CHANTS'));
        await tester.pump();

        expect(find.textContaining('Setup is saved'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(find.text('ENTER CHANTS'), findsNothing);
        final displayNameField = tester.widget<TextFormField>(
          find.byKey(const Key('onboarding-display-name-field')),
        );
        expect(displayNameField.enabled, isFalse);
        expect(displayNameField.controller?.text, 'Testuser');
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox)).onChanged,
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

    testWidgets('policy agreement keeps one calm aligned form hierarchy', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(OnboardingScreen(onDestinationSelected: (_) {})),
      );

      final checkboxRect = tester.getRect(find.byType(Checkbox));
      final agreementRect = tester.getRect(
        find.text('I agree to the Terms and Community Rules.'),
      );
      expect(agreementRect.left, greaterThan(checkboxRect.left));
      expect(agreementRect.left - checkboxRect.right, lessThanOrEqualTo(12));
      expect((agreementRect.top - checkboxRect.top).abs(), lessThan(16));
      final policySurface = tester.widget<Container>(
        find.byKey(const Key('onboarding-policy-consent')),
      );
      final policyDecoration = policySurface.decoration as BoxDecoration;
      expect(policyDecoration.color, AppColors.surface);
      expect(
        tester
            .getSize(find.byKey(const Key('onboarding-policy-toggle')))
            .height,
        greaterThanOrEqualTo(48),
      );

      final appBarTitleRect = tester.getRect(find.text('WELCOME TO CHANTS'));
      final sectionTitleRect = tester.getRect(find.text('ONE LAST VERSE'));
      expect((appBarTitleRect.left - sectionTitleRect.left).abs(), lessThan(1));

      final displayLabelRect = tester.getRect(find.text('DISPLAY NAME'));
      final displayFieldRect = tester.getRect(
        find.byKey(const Key('onboarding-display-name-field')),
      );
      final birthLabelRect = tester.getRect(find.text('DATE OF BIRTH'));
      final birthFieldRect = tester.getRect(
        find.byKey(const Key('onboarding-date-field')),
      );
      expect(displayLabelRect.bottom, lessThan(displayFieldRect.top));
      expect(birthLabelRect.bottom, lessThan(birthFieldRect.top));
      expect(
        (displayLabelRect.left - displayFieldRect.left).abs(),
        lessThan(1),
      );
      expect((birthLabelRect.left - birthFieldRect.left).abs(), lessThan(1));

      final displayField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('onboarding-display-name-field')),
          matching: find.byType(TextField),
        ),
      );
      final birthField = tester.widget<InputDecorator>(
        find.byKey(const Key('onboarding-date-field')),
      );
      expect(displayField.decoration?.labelText, isNull);
      expect(birthField.decoration.labelText, isNull);

      for (final label in ['Terms', 'Community Rules', 'Privacy notice']) {
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, label),
        );
        expect(
          button.style?.foregroundColor?.resolve(<WidgetState>{}),
          AppColors.textMuted,
        );
        expect(
          button.style?.minimumSize?.resolve(<WidgetState>{})?.height,
          greaterThanOrEqualTo(48),
        );
      }

      final destination = tester.widget<SegmentedButton<int>>(
        find.byType(SegmentedButton<int>),
      );
      expect(destination.showSelectedIcon, isFalse);
      expect(
        destination.style?.backgroundColor?.resolve({WidgetState.selected}),
        AppColors.surfaceRaised,
      );
      expect(
        destination.style?.foregroundColor?.resolve({WidgetState.selected}),
        AppColors.textHeadline,
      );
      expect(
        destination.style?.side?.resolve({WidgetState.selected}),
        const BorderSide(color: AppColors.gold, width: 1.5),
      );
      expect(
        destination.style?.textStyle?.resolve({
          WidgetState.selected,
        })?.fontWeight,
        FontWeight.w800,
      );
    });

    testWidgets('onboarding stays usable at 320 pixels and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.8),
            ),
            child: OnboardingScreen(onDestinationSelected: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('ENTER CHANTS'),
        find.byType(ListView),
        const Offset(0, -320),
      );
      expect(find.text('ENTER CHANTS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
