import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/data/models/auth_feature_config.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/data/repositories/magic_link_store.dart';
import 'package:chants/presentation/auth/email_verification_screen.dart';
import 'package:chants/presentation/auth/email_sign_in_screen.dart';
import 'package:chants/presentation/auth/magic_link_screen.dart';
import 'package:chants/presentation/auth/onboarding_screen.dart';
import 'package:chants/presentation/auth/password_reset_screen.dart';
import 'package:chants/presentation/auth/phone_auth_screen.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';
import 'package:chants/presentation/settings/sign_in_methods_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UiAuthRepository extends Mock implements AuthRepository {
  Object? resetError;
  Object? appleError;
  Object? magicLinkError;
  bool verificationRequested = true;
  User? user;
  int reloadCalls = 0;
  int phoneSendCalls = 0;

  @override
  User? get currentUser => user;

  @override
  Future<void> sendPasswordReset({required String email}) async {
    final error = resetError;
    if (error != null) throw error;
  }

  @override
  Future<void> reloadCurrentUser() async {
    reloadCalls += 1;
  }

  @override
  Future<bool> sendEmailVerification() async => verificationRequested;

  @override
  Future<void> sendMagicLink({
    required String email,
    required String continueUrl,
    required String linkDomain,
  }) async {
    final error = magicLinkError;
    if (error != null) throw error;
  }

  @override
  Future<PhoneVerificationStart> startPhoneVerification({
    required String phoneNumber,
    required bool linkToCurrentUser,
    int? forceResendingToken,
    PhoneVerificationAttempt? attempt,
    FutureOr<void> Function()? onLateCredentialAccepted,
  }) async {
    phoneSendCalls += 1;
    return PhoneVerificationStart.codeSent(
      verificationId: 'verification-id',
      resendToken: 7,
      attempt: attempt ?? PhoneVerificationAttempt(),
    );
  }

  @override
  Future<UserCredential> signInWithApple() async {
    throw appleError ?? StateError('Apple was not configured for this test.');
  }
}

class _UiUser extends Mock implements User {
  @override
  final String uid = 'fan';
  @override
  final bool emailVerified = false;
  @override
  final List<UserInfo> providerData = const [];
}

class _UnusedPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingMagicLinkStore extends MagicLinkStore {
  String? email;
  String? linkingUid;
  int clearCalls = 0;

  _RecordingMagicLinkStore() : super(preferences: _UnusedPreferences());

  @override
  Future<void> save({required String email, String? linkingUid}) async {
    this.email = email;
    this.linkingUid = linkingUid;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    email = null;
    linkingUid = null;
  }
}

void main() {
  Widget wrap(
    Widget child, {
    AuthFeatureConfig config = const AuthFeatureConfig(),
    _UiAuthRepository? repository,
    MagicLinkStore? magicLinkStore,
    RouteFactory? onGenerateRoute,
    double textScale = 1,
  }) {
    return ProviderScope(
      overrides: [
        authFeatureConfigProvider.overrideWithValue(config),
        authRepositoryProvider.overrideWithValue(
          repository ?? _UiAuthRepository(),
        ),
        if (magicLinkStore != null)
          magicLinkStoreProvider.overrideWithValue(magicLinkStore),
      ],
      child: MaterialApp(
        onGenerateRoute: onGenerateRoute,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    );
  }

  testWidgets('welcome keeps unconfigured providers invisible', (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    expect(find.text('CONTINUE WITH EMAIL'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('CONTINUE WITH APPLE'), findsNothing);
    expect(find.text('CONTINUE WITH GOOGLE'), findsNothing);
    expect(find.text('MORE WAYS TO SIGN IN'), findsNothing);
    expect(find.text('PRIVACY'), findsOneWidget);
    expect(find.text('TERMS'), findsOneWidget);
    expect(find.text('COMMUNITY'), findsOneWidget);
    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('HELP & POLICIES'), findsOneWidget);
  });

  testWidgets('signed-out welcome reaches all six launch documents', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SignInScreen(), onGenerateRoute: AppRouter.onGenerateRoute),
    );

    await tester.scrollUntilVisible(
      find.text('HELP & POLICIES'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('HELP & POLICIES'));
    await tester.pumpAndSettle();

    for (final label in [
      'PRIVACY NOTICE',
      'TERMS OF USE',
      'COMMUNITY RULES',
      'RIGHTS AND TAKEDOWN',
      'DELETE ACCOUNT',
      'SUPPORT',
    ]) {
      final destination = find.widgetWithText(ListTile, label);
      expect(destination, findsOneWidget);
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'configured primary and secondary methods keep the intended hierarchy',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const SignInScreen(),
          config: const AuthFeatureConfig.allForTesting(),
        ),
      );

      expect(find.text('CONTINUE WITH APPLE'), findsOneWidget);
      expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
      expect(find.text('CONTINUE WITH EMAIL'), findsOneWidget);
      expect(find.text('CONTINUE WITH FACEBOOK'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('MORE WAYS TO SIGN IN'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('MORE WAYS TO SIGN IN'));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('CONTINUE WITH FACEBOOK'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('CONTINUE WITH FACEBOOK'), findsOneWidget);
      expect(find.text('CONTINUE WITH PHONE'), findsOneWidget);
    },
  );

  testWidgets('welcome stays usable at narrow width and 1.8x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(
        const SignInScreen(),
        config: const AuthFeatureConfig.allForTesting(),
        textScale: 1.8,
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider cancellation restores the welcome without an error', (
    tester,
  ) async {
    final repository = _UiAuthRepository()
      ..appleError = const AuthFlowCancelledException();
    await tester.pumpWidget(
      wrap(
        const SignInScreen(),
        config: const AuthFeatureConfig.allForTesting(),
        repository: repository,
      ),
    );

    await tester.tap(find.text('CONTINUE WITH APPLE'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('could not be completed'), findsNothing);
  });

  testWidgets('provider collision gives the explicit non-merge recovery', (
    tester,
  ) async {
    final repository = _UiAuthRepository()
      ..appleError = FirebaseAuthException(code: 'credential-already-in-use');
    await tester.pumpWidget(
      wrap(
        const SignInScreen(),
        config: const AuthFeatureConfig.allForTesting(),
        repository: repository,
      ),
    );

    await tester.tap(find.text('CONTINUE WITH APPLE'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.textContaining('belongs to another account'), findsOneWidget);
    expect(find.textContaining('then link this one from You'), findsOneWidget);
  });

  for (final surface in <String, Widget>{
    'email sign-in': const EmailSignInScreen(),
    'email signup': const SignUpScreen(),
    'email verification': const EmailVerificationScreen(
      email: 'fan@example.com',
    ),
    'password reset': const PasswordResetScreen(),
    'magic-link request': const MagicLinkScreen(linkToCurrentUser: false),
    'phone entry': const PhoneAuthScreen(linkToCurrentUser: false),
    'supporter onboarding': OnboardingScreen(onDestinationSelected: (_) {}),
    'sign-in methods': const SignInMethodsScreen(),
  }.entries) {
    testWidgets('${surface.key} stays usable at narrow width and 1.8x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          surface.value,
          config: const AuthFeatureConfig.allForTesting(),
          textScale: 1.8,
        ),
      );

      expect(find.byType(Scrollable), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('password reset does not claim success on a known failure', (
    tester,
  ) async {
    final repository = _UiAuthRepository()
      ..resetError = FirebaseAuthException(code: 'network-request-failed');
    await tester.pumpWidget(
      wrap(const PasswordResetScreen(), repository: repository),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'fan@example.com',
    );
    await tester.tap(find.text('SEND RESET LINK'));
    await tester.pump();

    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('If that email is registered'), findsNothing);
  });

  testWidgets(
    'email verification refreshes once on app return without polling',
    (tester) async {
      final repository = _UiAuthRepository();
      await tester.pumpWidget(
        wrap(
          const EmailVerificationScreen(email: 'fan@example.com'),
          repository: repository,
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(repository.reloadCalls, 1);

      await tester.pump(const Duration(minutes: 5));
      expect(repository.reloadCalls, 1);
    },
  );

  testWidgets(
    'phone flow validates format and consent before calling Firebase',
    (tester) async {
      await tester.pumpWidget(
        wrap(const PhoneAuthScreen(linkToCurrentUser: false)),
      );

      await tester.tap(find.text('SEND CODE'));
      await tester.pump();
      expect(find.textContaining('international format'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Mobile number'),
        '+447700900123',
      );
      await tester.tap(find.text('SEND CODE'));
      await tester.pump();
      expect(find.textContaining('disclosure'), findsOneWidget);
    },
  );

  testWidgets('phone linking fails before SMS when the session is gone', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const PhoneAuthScreen(linkToCurrentUser: true),
        config: const AuthFeatureConfig.allForTesting(),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Mobile number'),
      '+447700900123',
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('SEND CODE'));
    await tester.pump();

    expect(find.textContaining('Sign in again'), findsOneWidget);
  });

  testWidgets('change number cannot bypass the active SMS cooldown', (
    tester,
  ) async {
    final repository = _UiAuthRepository();
    await tester.pumpWidget(
      wrap(
        const PhoneAuthScreen(linkToCurrentUser: false),
        repository: repository,
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Mobile number'),
      '+447700900123',
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('SEND CODE'));
    await tester.pump();

    expect(repository.phoneSendCalls, 1);
    expect(find.text('CHANGE NUMBER'), findsOneWidget);
    await tester.tap(find.text('CHANGE NUMBER'));
    await tester.pump();

    expect(find.text('SEND AGAIN IN 60s'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(repository.phoneSendCalls, 1);
  });

  testWidgets('magic-link linking fails before send when the session is gone', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MagicLinkScreen(linkToCurrentUser: true),
        config: const AuthFeatureConfig.allForTesting(),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'fan@example.com',
    );
    await tester.tap(find.text('SEND SIGN-IN LINK'));
    await tester.pump();

    expect(find.textContaining('Sign in again'), findsOneWidget);
  });

  testWidgets('ambiguous magic-link send failure preserves pending binding', (
    tester,
  ) async {
    final repository = _UiAuthRepository()
      ..magicLinkError = FirebaseAuthException(code: 'network-request-failed');
    final store = _RecordingMagicLinkStore();
    await tester.pumpWidget(
      wrap(
        const MagicLinkScreen(linkToCurrentUser: false),
        config: const AuthFeatureConfig.allForTesting(),
        repository: repository,
        magicLinkStore: store,
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'fan@example.com',
    );
    await tester.tap(find.text('SEND SIGN-IN LINK'));
    await tester.pump();

    expect(store.email, 'fan@example.com');
    expect(store.clearCalls, 0);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('already verified email never claims another message was sent', (
    tester,
  ) async {
    final repository = _UiAuthRepository()..verificationRequested = false;
    await tester.pumpWidget(
      wrap(
        const EmailVerificationScreen(email: 'fan@example.com'),
        repository: repository,
      ),
    );

    await tester.tap(find.text('RESEND EMAIL'));
    await tester.pump();

    expect(find.textContaining('already verified'), findsOneWidget);
    expect(find.textContaining('Verification email sent'), findsNothing);
    expect(repository.reloadCalls, 1);
  });

  testWidgets('email-link return says completion is still required', (
    tester,
  ) async {
    final repository = _UiAuthRepository()..user = _UiUser();
    final store = _RecordingMagicLinkStore();
    await tester.pumpWidget(
      wrap(
        const SignInMethodsScreen(),
        config: const AuthFeatureConfig(magicLinkEnabled: true),
        repository: repository,
        magicLinkStore: store,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('CONNECT EMAIL LINK'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'fan@example.com',
    );
    await tester.tap(find.text('SEND SIGN-IN LINK'));
    await tester.pump();
    expect(find.text('LINK SENT'), findsOneWidget);
    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Open it on this device'), findsOneWidget);
    expect(find.text('Sign-in method connected.'), findsNothing);
    expect(repository.reloadCalls, 0);
  });
}
