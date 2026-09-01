import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
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
  Future<Map<String, dynamic>> mergeChants({
    required String sourceId,
    required String targetId,
  }) async {
    return {};
  }

  @override
  Future<void> promoteChant(String chantId) async {}
  @override
  Future<void> removeChant(String chantId) async {}
  @override
  Future<void> removeChantEvidence(String chantId) async {}
  @override
  Future<void> removeComment(String commentId) async {}
  @override
  Future<void> unhideChant(String chantId) async {}
  @override
  Future<void> unhideComment(String commentId) async {}
  @override
  Future<void> moderatePublishedPerformance({
    required String targetType,
    required String targetId,
    required String action,
  }) async {}
}

void main() {
  Widget wrap(Widget child, ModerationRepository repo, {double textScale = 1}) {
    return ProviderScope(
      overrides: [moderationRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    );
  }

  group('PolicyAcceptanceGateScreen', () {
    testWidgets('renders the accepted documents and separate privacy notice', (
      tester,
    ) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      expect(find.text('COMMUNITY RULES'), findsOneWidget);
      expect(find.text('READ TERMS'), findsOneWidget);
      expect(find.text('PRIVACY NOTICE'), findsOneWidget);
      expect(find.text('HELP & POLICIES'), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('DELETE ACCOUNT'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);
      expect(find.textContaining('not part of this agreement'), findsOneWidget);
      expect(find.textContaining('contract version v2'), findsOneWidget);
      expect(
        find.text('KEEP THE TERRACE LOUD.\nKEEP IT SAFE.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'TERMS OF USE. The legal agreement for using Chants. READ TERMS',
        ),
        findsOneWidget,
      );
      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
    });

    testWidgets('tapping agree and continue calls acceptPolicy', (
      tester,
    ) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      // Not pumpAndSettle: on success the screen intentionally stays in its
      // busy state and never navigates itself away (ChantApp's reactive
      // gate does that once the profile stream catches up), so the loading
      // spinner never settles.
      await tester.pump();
      await tester.pump();

      expect(repo.acceptPolicyCalls, 1);
    });

    testWidgets('shows an error and stays usable if acceptPolicy fails', (
      tester,
    ) async {
      final repo = _FakeModerationRepository()..shouldFail = true;
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
      // Button is usable again, not stuck in a loading state.
      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
    });

    testWidgets('opens the full terms without accepting', (tester) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.scrollUntilVisible(
        find.text('READ TERMS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('READ TERMS'));
      await tester.pumpAndSettle();

      expect(find.text('TERMS OF USE'), findsWidgets);
      expect(find.text('YOUR CONTRIBUTIONS'), findsOneWidget);
      expect(repo.acceptPolicyCalls, 0);
    });

    testWidgets('opens support without accepting', (tester) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.scrollUntilVisible(
        find.text('SUPPORT'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('SUPPORT'));
      await tester.pumpAndSettle();

      expect(find.textContaining('support@chantsfc.com'), findsWidgets);
      expect(repo.acceptPolicyCalls, 0);
    });

    testWidgets('gate remains usable at 320 pixels and 1.8x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _FakeModerationRepository();

      await tester.pumpWidget(
        wrap(const PolicyAcceptanceGateScreen(), repo, textScale: 1.8),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('policy-gate-scroll')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('DELETE ACCOUNT'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('DELETE ACCOUNT'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);

      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
      final buttonRect = tester.getRect(
        find.byKey(const ValueKey('policy-accept-button')),
      );
      expect(buttonRect.left, greaterThanOrEqualTo(0));
      expect(buttonRect.top, greaterThanOrEqualTo(0));
      expect(buttonRect.right, lessThanOrEqualTo(320));
      expect(buttonRect.bottom, lessThanOrEqualTo(568));
      expect(tester.takeException(), isNull);
    });
  });
}
