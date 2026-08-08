/// The content policy version this build of the app expects.
///
/// Bumped only for a substantive change to the policy text. Bumping it
/// re-gates every existing user behind the acceptance screen on next open,
/// so treat a bump as a deliberate, rare, well-communicated event.
///
/// This string must match CURRENT_POLICY_VERSION in functions/src/index.ts
/// and the version check in firestore.rules. There is no shared-constant
/// mechanism between Dart and the Cloud Functions, so all three copies are
/// kept in sync by hand.
const String kCurrentPolicyVersion = 'v1';
