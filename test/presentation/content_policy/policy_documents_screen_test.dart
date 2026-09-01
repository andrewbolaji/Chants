import 'package:chants/app/router.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';
import 'package:chants/presentation/content_policy/policy_documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({double textScale = 1}) {
    return MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const PolicyHubScreen(),
      ),
    );
  }

  testWidgets('policy hub lists every launch document', (tester) async {
    await tester.pumpWidget(app());

    for (final label in [
      'PRIVACY NOTICE',
      'TERMS OF USE',
      'COMMUNITY RULES',
      'RIGHTS AND TAKEDOWN',
      'DELETE ACCOUNT',
      'SUPPORT',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('community rules identify the contract and child-safety route', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ContentPolicyScreen()));

    expect(find.textContaining('Effective 31 August 2026'), findsOneWidget);
    expect(find.textContaining('contract version v2'), findsOneWidget);
    expect(find.text('URGENT CHILD SAFETY'), findsOneWidget);
    expect(find.textContaining('support@chantsfc.com'), findsOneWidget);
    expect(find.textContaining('Do not download or forward'), findsOneWidget);
  });

  testWidgets('deletion instructions are complete without signing in', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('DELETE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('WITHOUT THE APP'), findsOneWidget);
    expect(find.textContaining('support@chantsfc.com'), findsOneWidget);
    expect(find.textContaining('30 calendar days'), findsOneWidget);
    expect(find.textContaining('Never send a password'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets(
    'approved business correspondence is visible without signing in',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('SUPPORT'));
      await tester.pumpAndSettle();

      expect(find.textContaining('5667 Treaschwig Rd #1014'), findsOneWidget);
      expect(find.textContaining('ThunderRiver Tech LLC'), findsOneWidget);
    },
  );

  testWidgets('every policy remains usable at 320 pixels and 1.8x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final document in <Widget>[
      privacyDocument,
      termsDocument,
      const ContentPolicyScreen(),
      rightsDocument,
      deletionDocument,
      supportDocument,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: document,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectionArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
