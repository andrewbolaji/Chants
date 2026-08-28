import 'package:flutter/foundation.dart';

@immutable
class AuthFeatureConfig {
  final bool appleEnabled;
  final bool googleEnabled;
  final bool facebookEnabled;
  final bool magicLinkEnabled;
  final bool phoneEnabled;
  final String magicLinkContinueUrl;
  final String magicLinkDomain;
  final String googleClientId;
  final String googleServerClientId;

  const AuthFeatureConfig({
    this.appleEnabled = false,
    this.googleEnabled = false,
    this.facebookEnabled = false,
    this.magicLinkEnabled = false,
    this.phoneEnabled = false,
    this.magicLinkContinueUrl = '',
    this.magicLinkDomain = '',
    this.googleClientId = '',
    this.googleServerClientId = '',
  });

  const AuthFeatureConfig.allForTesting()
    : appleEnabled = true,
      googleEnabled = true,
      facebookEnabled = true,
      magicLinkEnabled = true,
      phoneEnabled = true,
      magicLinkContinueUrl = 'https://auth.chantsfc.com/finish-sign-in',
      magicLinkDomain = 'auth.chantsfc.com',
      googleClientId = 'test-client-id',
      googleServerClientId = 'test-server-client-id';

  factory AuthFeatureConfig.fromEnvironment() {
    const magicRequested = bool.fromEnvironment(
      'CHANTS_ENABLE_MAGIC_LINK_AUTH',
    );
    const continueUrl = String.fromEnvironment(
      'CHANTS_MAGIC_LINK_CONTINUE_URL',
    );
    const linkDomain = String.fromEnvironment('CHANTS_MAGIC_LINK_DOMAIN');
    return const AuthFeatureConfig(
      appleEnabled: bool.fromEnvironment('CHANTS_ENABLE_APPLE_AUTH'),
      googleEnabled: bool.fromEnvironment('CHANTS_ENABLE_GOOGLE_AUTH'),
      facebookEnabled: bool.fromEnvironment('CHANTS_ENABLE_FACEBOOK_AUTH'),
      magicLinkEnabled: magicRequested && continueUrl != '' && linkDomain != '',
      phoneEnabled: bool.fromEnvironment('CHANTS_ENABLE_PHONE_AUTH'),
      magicLinkContinueUrl: continueUrl,
      magicLinkDomain: linkDomain,
      googleClientId: String.fromEnvironment('CHANTS_GOOGLE_CLIENT_ID'),
      googleServerClientId: String.fromEnvironment(
        'CHANTS_GOOGLE_SERVER_CLIENT_ID',
      ),
    );
  }

  bool get hasSecondaryMethods => facebookEnabled || phoneEnabled;
}
