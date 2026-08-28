import 'package:chants/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

String authErrorMessage(Object error) {
  if (error is AuthProviderUnavailableException ||
      error is GoogleSignInException) {
    return 'That sign-in method is not available right now. Try another way.';
  }
  if (error is PhoneVerificationInProgressException) {
    return 'Verification is already finishing.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'account-exists-with-different-credential' ||
      'credential-already-in-use' =>
        'That identity belongs to another account. Sign in with your existing '
            'method, then link this one from You.',
      'network-request-failed' =>
        'You appear to be offline. Reconnect and try again.',
      'operation-not-allowed' =>
        'That sign-in method is not available right now. Try another way.',
      'too-many-requests' || 'quota-exceeded' =>
        'Too many attempts. Wait a moment before trying again.',
      'user-disabled' => 'This account is unavailable.',
      'requires-recent-login' =>
        'Sign out, sign in again, then repeat this account change.',
      'invalid-verification-code' => 'That code is not correct. Try again.',
      'session-expired' ||
      'code-expired' => 'That code expired. Request a new one.',
      'invalid-phone-number' =>
        'Enter a valid mobile number with its country code.',
      'provider-already-linked' => 'That sign-in method is already connected.',
      _ => 'Sign-in could not be completed. Try again.',
    };
  }
  return 'Sign-in could not be completed. Try again.';
}
