import 'dart:async';

import 'package:chants/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockFacebookAuth extends Mock implements FacebookAuth {}

class _MockPhoneCredential extends Mock implements PhoneAuthCredential {}

class _MockUserCredential extends Mock implements UserCredential {}

class _PhoneFirebaseAuth extends Mock implements FirebaseAuth {
  PhoneVerificationCompleted? verificationCompletedCallback;
  PhoneCodeSent? codeSentCallback;
  int signInCalls = 0;
  Completer<UserCredential>? blockedSignIn;

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    verificationCompletedCallback = verificationCompleted;
    codeSentCallback = codeSent;
    codeSent('verification-id', 7);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    signInCalls += 1;
    final blocker = blockedSignIn;
    if (blocker != null) return blocker.future;
    return _MockUserCredential();
  }
}

void main() {
  test(
    'late Android auto-verification closes the already-open code flow',
    () async {
      final auth = _PhoneFirebaseAuth();
      final repository = AuthRepository(
        auth: auth,
        googleSignIn: _MockGoogleSignIn(),
        facebookAuth: _MockFacebookAuth(),
      );
      final lateAccepted = Completer<void>();

      final start = await repository.startPhoneVerification(
        phoneNumber: '+447700900123',
        linkToCurrentUser: false,
        onLateCredentialAccepted: lateAccepted.complete,
      );
      expect(start.verificationId, 'verification-id');
      expect(start.completedAutomatically, isFalse);

      auth.verificationCompletedCallback!(_MockPhoneCredential());
      await lateAccepted.future;

      expect(auth.signInCalls, 1);
    },
  );

  test('manual and automatic completion share one credential claim', () async {
    final auth = _PhoneFirebaseAuth();
    final repository = AuthRepository(
      auth: auth,
      googleSignIn: _MockGoogleSignIn(),
      facebookAuth: _MockFacebookAuth(),
    );
    final start = await repository.startPhoneVerification(
      phoneNumber: '+447700900123',
      linkToCurrentUser: false,
    );
    auth.blockedSignIn = Completer<UserCredential>();

    final manual = repository.completePhoneVerification(
      verificationId: start.verificationId!,
      smsCode: '123456',
      linkToCurrentUser: false,
      attempt: start.attempt,
    );
    auth.verificationCompletedCallback!(_MockPhoneCredential());
    await Future<void>.delayed(Duration.zero);
    expect(auth.signInCalls, 1);

    auth.blockedSignIn!.complete(_MockUserCredential());
    await manual;
    expect(auth.signInCalls, 1);
  });

  test('resend reuses the credential claim across verification IDs', () async {
    final auth = _PhoneFirebaseAuth();
    final repository = AuthRepository(
      auth: auth,
      googleSignIn: _MockGoogleSignIn(),
      facebookAuth: _MockFacebookAuth(),
    );
    final first = await repository.startPhoneVerification(
      phoneNumber: '+447700900123',
      linkToCurrentUser: false,
    );
    final firstAutomaticCallback = auth.verificationCompletedCallback!;
    final second = await repository.startPhoneVerification(
      phoneNumber: '+447700900123',
      linkToCurrentUser: false,
      forceResendingToken: first.resendToken,
      attempt: first.attempt,
    );
    auth.blockedSignIn = Completer<UserCredential>();

    final manual = repository.completePhoneVerification(
      verificationId: second.verificationId!,
      smsCode: '123456',
      linkToCurrentUser: false,
      attempt: second.attempt,
    );
    firstAutomaticCallback(_MockPhoneCredential());
    await Future<void>.delayed(Duration.zero);
    expect(auth.signInCalls, 1);

    auth.blockedSignIn!.complete(_MockUserCredential());
    await manual;
    expect(auth.signInCalls, 1);
  });

  test('cancelled verification ignores a later automatic credential', () async {
    final auth = _PhoneFirebaseAuth();
    final repository = AuthRepository(
      auth: auth,
      googleSignIn: _MockGoogleSignIn(),
      facebookAuth: _MockFacebookAuth(),
    );
    final start = await repository.startPhoneVerification(
      phoneNumber: '+447700900123',
      linkToCurrentUser: false,
    );

    start.attempt!.cancel();
    auth.verificationCompletedCallback!(_MockPhoneCredential());
    await Future<void>.delayed(Duration.zero);

    expect(auth.signInCalls, 0);
  });

  test(
    'cancellation stays terminal after an in-flight credential fails',
    () async {
      final auth = _PhoneFirebaseAuth();
      final repository = AuthRepository(
        auth: auth,
        googleSignIn: _MockGoogleSignIn(),
        facebookAuth: _MockFacebookAuth(),
      );
      final start = await repository.startPhoneVerification(
        phoneNumber: '+447700900123',
        linkToCurrentUser: false,
      );
      auth.blockedSignIn = Completer<UserCredential>();

      auth.verificationCompletedCallback!(_MockPhoneCredential());
      await Future<void>.delayed(Duration.zero);
      expect(auth.signInCalls, 1);

      start.attempt!.cancel();
      auth.blockedSignIn!.completeError(StateError('credential rejected'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      auth.verificationCompletedCallback!(_MockPhoneCredential());
      await Future<void>.delayed(Duration.zero);
      expect(auth.signInCalls, 1);
    },
  );
}
