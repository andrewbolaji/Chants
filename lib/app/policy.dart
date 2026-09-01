/// The Terms and Community Rules version this build of the app expects.
///
/// Bumped only for a substantive change to either accepted document. Bumping it
/// re-gates every existing user behind the acceptance screen on next open,
/// so treat a bump as a deliberate, rare, well-communicated event.
///
/// This string must match CURRENT_POLICY_VERSION in functions/src/policy.ts
/// and the version check in firestore.rules. There is no shared-constant
/// mechanism between Dart and the Cloud Functions, so all three copies are
/// kept in sync by hand.
const String kCurrentPolicyVersion = 'v2';

const String kPolicyEffectiveDate = '31 August 2026';
const String kSupportEmail = 'support@chantsfc.com';
const String kBusinessCorrespondenceAddress =
    'ThunderRiver Tech LLC, 5667 Treaschwig Rd #1014, Spring, TX 77373, '
    'United States';
