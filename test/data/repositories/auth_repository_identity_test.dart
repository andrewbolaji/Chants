import 'package:chants/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockFacebookAuth extends Mock implements FacebookAuth {}

class _AppleCancellationUser extends Mock implements User {
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) {
    throw FirebaseAuthException(code: 'canceled');
  }
}

class _AppleCancellationAuth extends Mock implements FirebaseAuth {
  @override
  final User? currentUser;

  _AppleCancellationAuth({this.currentUser});

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) {
    throw FirebaseAuthException(code: 'canceled');
  }
}

class _ProviderInfo extends Mock implements UserInfo {
  @override
  final String providerId;

  _ProviderInfo(this.providerId);
}

class _IdentityUser extends Mock implements User {
  @override
  final bool emailVerified;
  @override
  final String? phoneNumber;
  @override
  final List<UserInfo> providerData;
  int unlinkCalls = 0;

  _IdentityUser({
    this.emailVerified = false,
    this.phoneNumber,
    List<String> providers = const [],
  }) : providerData = providers.map(_ProviderInfo.new).toList();

  @override
  Future<User> unlink(String providerId) async {
    unlinkCalls += 1;
    return this;
  }
}

class _IdentityAuth extends Mock implements FirebaseAuth {
  @override
  final User? currentUser;

  _IdentityAuth(this.currentUser);
}

AuthRepository repositoryFor(User user) {
  return AuthRepository(
    auth: _IdentityAuth(user),
    googleSignIn: _MockGoogleSignIn(),
    facebookAuth: _MockFacebookAuth(),
  );
}

void main() {
  test(
    'Apple cancellation is a quiet flow result for sign-in and link',
    () async {
      final signInRepository = AuthRepository(
        auth: _AppleCancellationAuth(),
        googleSignIn: _MockGoogleSignIn(),
        facebookAuth: _MockFacebookAuth(),
      );
      await expectLater(
        signInRepository.signInWithApple(),
        throwsA(isA<AuthFlowCancelledException>()),
      );

      final linkRepository = AuthRepository(
        auth: _AppleCancellationAuth(currentUser: _AppleCancellationUser()),
        googleSignIn: _MockGoogleSignIn(),
        facebookAuth: _MockFacebookAuth(),
      );
      await expectLater(
        linkRepository.linkApple(),
        throwsA(isA<AuthFlowCancelledException>()),
      );
    },
  );

  test(
    'contact authority accepts verified email, phone, or trusted provider',
    () {
      final repository = repositoryFor(_IdentityUser());

      expect(
        repository.isContactVerified(_IdentityUser(emailVerified: true)),
        isTrue,
      );
      expect(
        repository.isContactVerified(
          _IdentityUser(phoneNumber: '+447700900123'),
        ),
        isTrue,
      );
      for (final provider in ['apple.com', 'google.com', 'facebook.com']) {
        expect(
          repository.isContactVerified(_IdentityUser(providers: [provider])),
          isTrue,
        );
      }
      expect(
        repository.isContactVerified(
          _IdentityUser(providers: ['password', 'github.com']),
        ),
        isFalse,
      );
    },
  );

  test('unlink refuses the final method and permits one of two', () async {
    final finalUser = _IdentityUser(providers: ['password']);
    await expectLater(
      repositoryFor(finalUser).unlinkProvider('password'),
      throwsA(isA<LastSignInMethodException>()),
    );
    expect(finalUser.unlinkCalls, 0);

    final linkedUser = _IdentityUser(providers: ['password', 'google.com']);
    await repositoryFor(linkedUser).unlinkProvider('google.com');
    expect(linkedUser.unlinkCalls, 1);
  });
}
