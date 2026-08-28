import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthFlowCancelledException implements Exception {
  const AuthFlowCancelledException();
}

class AuthProviderUnavailableException implements Exception {
  const AuthProviderUnavailableException();
}

class LastSignInMethodException implements Exception {
  const LastSignInMethodException();
}

class PhoneVerificationInProgressException implements Exception {
  const PhoneVerificationInProgressException();
}

class PhoneVerificationAttempt {
  bool _inFlight = false;
  bool _completed = false;
  bool _cancelled = false;

  bool begin() {
    if (_inFlight || _completed || _cancelled) return false;
    _inFlight = true;
    return true;
  }

  void complete() {
    _inFlight = false;
    _completed = true;
  }

  void release() {
    _inFlight = false;
    if (_cancelled) _completed = true;
  }

  void cancel() {
    _cancelled = true;
    if (!_inFlight) _completed = true;
  }
}

class PhoneVerificationStart {
  final String? verificationId;
  final int? resendToken;
  final bool completedAutomatically;
  final PhoneVerificationAttempt? attempt;

  const PhoneVerificationStart.codeSent({
    required String this.verificationId,
    required this.attempt,
    this.resendToken,
  }) : completedAutomatically = false;

  const PhoneVerificationStart.completed()
    : verificationId = null,
      resendToken = null,
      attempt = null,
      completedAutomatically = true;
}

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;
  Future<void>? _googleInitialization;

  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  Stream<User?> get authStateChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sends a password reset email. Returns the same message whether
  /// the email exists or not, to avoid leaking account existence.
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  }

  Future<bool> sendEmailVerification() async {
    final user = _requireCurrentUser();
    if (user.emailVerified) return false;
    await user.sendEmailVerification();
    return true;
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  bool isContactVerified(User user) {
    if (user.emailVerified || (user.phoneNumber?.trim().isNotEmpty ?? false)) {
      return true;
    }
    const trustedProviders = {'apple.com', 'google.com', 'facebook.com'};
    return user.providerData.any(
      (provider) => trustedProviders.contains(provider.providerId),
    );
  }

  Future<void> _initializeGoogle({
    required String clientId,
    required String serverClientId,
  }) {
    return _googleInitialization ??= _initializeGoogleOnce(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Future<void> _initializeGoogleOnce({
    required String clientId,
    required String serverClientId,
  }) async {
    try {
      await _googleSignIn.initialize(
        clientId: clientId.trim().isEmpty ? null : clientId.trim(),
        serverClientId: serverClientId.trim().isEmpty
            ? null
            : serverClientId.trim(),
      );
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  Future<AuthCredential> _googleCredential({
    required String clientId,
    required String serverClientId,
  }) async {
    try {
      await _initializeGoogle(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthProviderUnavailableException();
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFlowCancelledException();
      }
      rethrow;
    }
  }

  Future<AuthCredential> _facebookCredential() async {
    final result = await _facebookAuth.login(permissions: const ['email']);
    if (result.status == LoginStatus.cancelled) {
      throw const AuthFlowCancelledException();
    }
    final accessToken = result.accessToken;
    if (result.status != LoginStatus.success || accessToken == null) {
      throw const AuthProviderUnavailableException();
    }
    return FacebookAuthProvider.credential(accessToken.tokenString);
  }

  Future<UserCredential> signInWithApple() {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    return _normalizeAppleCancellation(
      () => _auth.signInWithProvider(provider),
    );
  }

  Future<UserCredential> signInWithGoogle({
    required String clientId,
    required String serverClientId,
  }) async {
    final credential = await _googleCredential(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    final credential = await _facebookCredential();
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> linkApple() {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    return _normalizeAppleCancellation(
      () => _requireCurrentUser().linkWithProvider(provider),
    );
  }

  Future<UserCredential> _normalizeAppleCancellation(
    Future<UserCredential> Function() action,
  ) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      if (const {
        'canceled',
        'cancelled',
        'web-context-canceled',
        'web-context-cancelled',
      }.contains(error.code)) {
        throw const AuthFlowCancelledException();
      }
      rethrow;
    }
  }

  Future<UserCredential> linkGoogle({
    required String clientId,
    required String serverClientId,
  }) async {
    final credential = await _googleCredential(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    return _requireCurrentUser().linkWithCredential(credential);
  }

  Future<UserCredential> linkFacebook() async {
    final credential = await _facebookCredential();
    return _requireCurrentUser().linkWithCredential(credential);
  }

  Future<PhoneVerificationStart> startPhoneVerification({
    required String phoneNumber,
    required bool linkToCurrentUser,
    int? forceResendingToken,
    PhoneVerificationAttempt? attempt,
    FutureOr<void> Function()? onLateCredentialAccepted,
  }) {
    final completer = Completer<PhoneVerificationStart>();
    final flowAttempt = attempt ?? PhoneVerificationAttempt();

    Future<void> acceptCredential(PhoneAuthCredential credential) async {
      if (!flowAttempt.begin()) return;
      try {
        if (linkToCurrentUser) {
          await _requireCurrentUser().linkWithCredential(credential);
        } else {
          await _auth.signInWithCredential(credential);
        }
        flowAttempt.complete();
        if (!completer.isCompleted) {
          completer.complete(const PhoneVerificationStart.completed());
        } else {
          await onLateCredentialAccepted?.call();
        }
      } catch (error, stackTrace) {
        flowAttempt.release();
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      }
    }

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: acceptCredential,
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationStart.codeSent(
              verificationId: verificationId,
              resendToken: resendToken,
              attempt: flowAttempt,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
    return completer.future;
  }

  Future<UserCredential> completePhoneVerification({
    required String verificationId,
    required String smsCode,
    required bool linkToCurrentUser,
    PhoneVerificationAttempt? attempt,
  }) async {
    if (attempt != null && !attempt.begin()) {
      throw const PhoneVerificationInProgressException();
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      final result = linkToCurrentUser
          ? await _requireCurrentUser().linkWithCredential(credential)
          : await _auth.signInWithCredential(credential);
      attempt?.complete();
      return result;
    } catch (_) {
      attempt?.release();
      rethrow;
    }
  }

  Future<void> sendMagicLink({
    required String email,
    required String continueUrl,
    required String linkDomain,
  }) {
    return _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: continueUrl,
        handleCodeInApp: true,
        iOSBundleId: 'com.chants.chants',
        androidPackageName: 'com.chants.chants',
        androidInstallApp: true,
        linkDomain: linkDomain,
      ),
    );
  }

  bool isMagicLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<UserCredential> completeMagicLink({
    required String email,
    required String link,
    required bool linkToCurrentUser,
  }) {
    if (linkToCurrentUser) {
      final credential = EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: link,
      );
      return _requireCurrentUser().linkWithCredential(credential);
    }
    return _auth.signInWithEmailLink(email: email, emailLink: link);
  }

  Set<String> linkedProviderIds() {
    return _requireCurrentUser().providerData
        .map((provider) => provider.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toSet();
  }

  Future<User> unlinkProvider(String providerId) async {
    final user = _requireCurrentUser();
    final providers = linkedProviderIds();
    if (providers.length <= 1 || !providers.contains(providerId)) {
      throw const LastSignInMethodException();
    }
    return user.unlink(providerId);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete();
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in account is available.');
    return user;
  }
}
