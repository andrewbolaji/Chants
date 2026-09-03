import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
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
  Object? acceptanceError;
  Completer<void>? pendingAcceptance;

  @override
  Future<void> acceptPolicy() async {
    acceptPolicyCalls++;
    if (acceptanceError case final error?) throw error;
    if (shouldFail) throw Exception('network error');
    await pendingAcceptance?.future;
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
    testWidgets('renders the accepted documents and quiet secondary routes', (
      tester,
    ) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      expect(find.text('COMMUNITY RULES'), findsOneWidget);
      expect(find.text('READ TERMS'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('policy-privacy-route')),
        findsOneWidget,
      );
      expect(find.text('OTHER OPTIONS'), findsOneWidget);
      expect(find.text('Help & policies'), findsNothing);
      expect(find.text('Support'), findsNothing);
      expect(find.text('Delete account'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
      expect(find.textContaining('Not part of this agreement'), findsOneWidget);
      expect(find.text('A QUICK RULES CHECK.'), findsOneWidget);
      expect(find.text('BANTER, NOT ABUSE'), findsNothing);
      expect(find.text('URGENT CHILD SAFETY'), findsNothing);
      expect(
        find.bySemanticsLabel(
          'TERMS OF USE. The legal agreement for using Chants. READ TERMS',
        ),
        findsOneWidget,
      );
      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('OTHER OPTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('OTHER OPTIONS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Help & policies'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('tapping agree and continue calls acceptPolicy', (
      tester,
    ) async {
      final repo = _FakeModerationRepository();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pump();
      await tester.pump();

      expect(repo.acceptPolicyCalls, 1);
      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
      expect(find.textContaining('Acceptance saved'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('policy-other-options')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('shows saving feedback and prevents duplicate acceptance', (
      tester,
    ) async {
      final repo = _FakeModerationRepository()
        ..pendingAcceptance = Completer<void>();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pump();

      expect(find.text('SAVING...'), findsOneWidget);
      expect(find.bySemanticsLabel('Saving policy acceptance'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('policy-accept-button')),
      );
      expect(button.onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('policy-accept-button')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(repo.acceptPolicyCalls, 1);

      repo.pendingAcceptance!.complete();
      await tester.pump();
      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
    });

    testWidgets('keeps help and support reachable while acceptance saves', (
      tester,
    ) async {
      final repo = _FakeModerationRepository()
        ..pendingAcceptance = Completer<void>();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('OTHER OPTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('OTHER OPTIONS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Help & policies'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      expect(
        find.textContaining('remain available while acceptance is saving'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Delete account'))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Sign out'))
            .enabled,
        isFalse,
      );

      await tester.tap(find.text('Support'));
      await tester.pumpAndSettle();
      expect(find.textContaining('support@chantsfc.com'), findsWidgets);

      repo.pendingAcceptance!.complete();
      await tester.pump();
    });

    testWidgets('a stalled acceptance times out and restores every action', (
      tester,
    ) async {
      final repo = _FakeModerationRepository()
        ..pendingAcceptance = Completer<void>();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pump();
      await tester.pump(kPolicyAcceptanceRequestTimeout);
      await tester.pump();

      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
      expect(
        find.textContaining('taking longer than expected'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('OTHER OPTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('OTHER OPTIONS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Delete account'))
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Sign out'))
            .enabled,
        isTrue,
      );
    });

    testWidgets('an open options sheet updates when acceptance finishes', (
      tester,
    ) async {
      final repo = _FakeModerationRepository()
        ..pendingAcceptance = Completer<void>();
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('OTHER OPTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('OTHER OPTIONS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Delete account'))
            .enabled,
        isFalse,
      );

      repo.pendingAcceptance!.complete();
      await tester.pump();

      expect(
        find.textContaining('remain available while acceptance is saving'),
        findsNothing,
      );
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Delete account'))
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Sign out'))
            .enabled,
        isTrue,
      );
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

    testWidgets('explains an intentional maintenance pause truthfully', (
      tester,
    ) async {
      final repo = _FakeModerationRepository()
        ..acceptanceError = FirebaseFunctionsException(
          code: 'unavailable',
          message: 'temporarily paused',
          details: const {'reason': 'maintenance'},
        );
      await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

      await tester.tap(find.text('AGREE AND CONTINUE'));
      await tester.pumpAndSettle();

      expect(find.textContaining('temporarily paused'), findsOneWidget);
      expect(find.textContaining('Nothing was changed'), findsOneWidget);
      expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
    });

    testWidgets('distinguishes every callable failure class', (tester) async {
      final cases = <(String, String)>[
        ('unauthenticated', 'Sign in again'),
        ('permission-denied', 'Verify an email address or phone number'),
        ('failed-precondition', 'account needs attention'),
        ('not-found', 'profile is not ready'),
        ('internal', 'could not save this right now'),
        ('unavailable', 'could not be reached'),
        ('deadline-exceeded', 'could not be reached'),
      ];

      for (final (code, expectedCopy) in cases) {
        final repo = _FakeModerationRepository()
          ..acceptanceError = FirebaseFunctionsException(
            code: code,
            message: 'test failure',
          );
        await tester.pumpWidget(wrap(const PolicyAcceptanceGateScreen(), repo));

        await tester.tap(find.text('AGREE AND CONTINUE'));
        await tester.pumpAndSettle();

        expect(find.textContaining(expectedCopy), findsOneWidget);
        expect(find.text('AGREE AND CONTINUE'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
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
        find.text('OTHER OPTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('OTHER OPTIONS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Support'));
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
        find.text('OTHER OPTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('OTHER OPTIONS'));
      await tester.pumpAndSettle();
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

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
