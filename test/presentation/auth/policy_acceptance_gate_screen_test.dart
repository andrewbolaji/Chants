import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';

// --- Fake (write boundary only, no logic reimplementation) ---
class _FakeModerationRepository implements ModerationRepository {
  int acceptPolicyCalls = 0;
  bool shouldFail = false;

  @override
  Future<void> acceptPolicy() async {
    if (shouldFail) throw Exception('network error');
    acceptPolicyCalls++;
  }

  @override
  Future<void> banUser(String userId) async {}
  @override
  Future<void> unbanUser(String userId) async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> demoteChant(String chantId) async {}
  @override
  Future<void> hideChant(String chantId) async {}
  @override
  Future<void> hideComment(String commentId) async {}
  @override
  Future<Map<String, dynamic>> mergeChants(
      {required String sourceId, required String targetId}) async {
    return {};
  }

  @override
  Future<void> promoteChant(String chantId) async {}
  @override
  Future<void> removeChant(String chantId) async {}
  @override
  Future<void> removeComment(String commentId) async {}
  @override
  Future<void> unhideChant(String chantId) async {}
  @override
  Future<void> unhideComment(String commentId) async {}
}

void main() {
  Widget wrap(Widget child, ModerationRepository repo) {
    return ProviderScope(
      overrides: [moderationRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  group('PolicyAcceptanceGateScreen', () {
    testWidgets('renders the policy text and an agree button',
        (tester) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(
          wrap(const PolicyAcceptanceGateScreen(), repo));

      expect(find.text('CONTENT POLICY'), findsOneWidget);
      expect(find.text('I AGREE'), findsOneWidget);
    });

    testWidgets('tapping I agree calls acceptPolicy', (tester) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(
          wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('I AGREE'));
      // Not pumpAndSettle: on success the screen intentionally stays in its
      // busy state and never navigates itself away (ChantApp's reactive
      // gate does that once the profile stream catches up), so the loading
      // spinner never settles.
      await tester.pump();
      await tester.pump();

      expect(repo.acceptPolicyCalls, 1);
    });

    testWidgets('shows an error and stays usable if acceptPolicy fails',
        (tester) async {
      final repo = _FakeModerationRepository()..shouldFail = true;
      await tester.pumpWidget(
          wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('I AGREE'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
      // Button is usable again, not stuck in a loading state.
      expect(find.text('I AGREE'), findsOneWidget);
    });
  });
}
