import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/first_run_orientation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  Future<void> Function()? onSkip,
  Future<void> Function()? onContinue,
  Future<void> Function()? onCreateAccount,
  double textScale = 1,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ChantTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: child!,
    ),
    home: FirstRunOrientationScreen(
      onSkip: onSkip ?? () async {},
      onContinue: onContinue ?? () async {},
      onCreateAccount: onCreateAccount ?? () async {},
    ),
  );
}

Future<void> _advance(WidgetTester tester, int count) async {
  for (var index = 0; index < count; index++) {
    await tester.tap(find.byKey(const Key('first-run-primary-action')));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('presents the three concise product truths in order', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('KNOW EVERY WORD'), findsOneWidget);
    expect(find.text('HOW CHANTS WORKS  1 / 3'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.byKey(const Key('first-run-brand-mark')), findsOneWidget);
    expect(find.byKey(const Key('first-run-dot-field-1')), findsOneWidget);
    final panelBottom = tester
        .getBottomLeft(find.byKey(const Key('first-run-visual-1')))
        .dy;
    final badgeBottom = tester.getBottomLeft(find.text('LEARN AND SAVE')).dy;
    expect(panelBottom - badgeBottom, lessThanOrEqualTo(24));
    final brandMark = tester.widget<Image>(
      find.byKey(const Key('first-run-brand-mark')),
    );
    expect((brandMark.image as AssetImage).assetName, 'assets/icon/splash.png');
    expect(
      find.text(
        'Find chants by club or player. Save the ones you need for matchday.',
      ),
      findsOneWidget,
    );

    await _advance(tester, 1);
    expect(find.text('BACK WHAT COMES NEXT'), findsOneWidget);
    expect(find.text('HOW CHANTS WORKS  2 / 3'), findsOneWidget);
    expect(find.text('STEP 02'), findsOneWidget);
    expect(find.byKey(const Key('first-run-dot-field-2')), findsOneWidget);
    final chantLabPanel = tester.widget<Container>(
      find.byKey(const Key('first-run-visual-2')),
    );
    final chantLabDecoration = chantLabPanel.decoration! as BoxDecoration;
    expect(chantLabDecoration.color, AppColors.surfaceRaised);
    expect(chantLabDecoration.border!.top.color, AppColors.outline);
    expect(
      find.text(
        'Back new ideas with your vote. Evidence they have been sung at matches earns Terrace Proven.',
      ),
      findsOneWidget,
    );

    await _advance(tester, 1);
    expect(find.text('ADD YOUR VOICE'), findsOneWidget);
    expect(find.text('HOW CHANTS WORKS  3 / 3'), findsOneWidget);
    expect(find.text('CONTINUE TO SIGN IN'), findsOneWidget);
    expect(find.text('STEP 03'), findsOneWidget);
    expect(find.byKey(const Key('first-run-dot-field-3')), findsOneWidget);
    expect(
      find.text(
        'Write a chant or perform one. Videos stay private until reviewed.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('horizontal drags move forward and backward between steps', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.drag(
      find.byKey(const Key('first-run-pages')),
      const Offset(-520, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('BACK WHAT COMES NEXT'), findsOneWidget);
    expect(find.text('HOW CHANTS WORKS  2 / 3'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('first-run-pages')),
      const Offset(520, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('KNOW EVERY WORD'), findsOneWidget);
    expect(find.text('HOW CHANTS WORKS  1 / 3'), findsOneWidget);
  });

  for (var step = 0; step < 3; step++) {
    testWidgets('skip exits from step ${step + 1}', (tester) async {
      var skipCalls = 0;
      await tester.pumpWidget(_app(onSkip: () async => skipCalls += 1));
      await _advance(tester, step);

      await tester.tap(find.byKey(const Key('first-run-skip')));
      await tester.pump();

      expect(skipCalls, 1);
    });

    testWidgets('create account exits from step ${step + 1}', (tester) async {
      var createCalls = 0;
      await tester.pumpWidget(
        _app(onCreateAccount: () async => createCalls += 1),
      );
      await _advance(tester, step);

      await tester.tap(find.byKey(const Key('first-run-create-account')));
      await tester.pump();

      expect(createCalls, 1);
    });
  }

  testWidgets('final continue exits to sign in only once', (tester) async {
    var continueCalls = 0;
    await tester.pumpWidget(_app(onContinue: () async => continueCalls += 1));
    await _advance(tester, 2);

    await tester.tap(find.byKey(const Key('first-run-primary-action')));
    await tester.pump();

    expect(continueCalls, 1);
  });

  testWidgets('an exit shows progress and prevents duplicate actions', (
    tester,
  ) async {
    final pending = Completer<void>();
    var skipCalls = 0;
    await tester.pumpWidget(
      _app(
        onSkip: () {
          skipCalls += 1;
          return pending.future;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('first-run-skip')));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('CONTINUING TO SIGN IN'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('first-run-skip')))
          .enabled,
      isFalse,
    );
    expect(find.byKey(const Key('first-run-primary-action')), findsNothing);
    expect(skipCalls, 1);

    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion changes steps without a transition frame', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduceMotion: true));

    await tester.tap(find.byKey(const Key('first-run-primary-action')));
    await tester.pump();

    expect(find.text('BACK WHAT COMES NEXT'), findsOneWidget);
    expect(find.text('KNOW EVERY WORD'), findsNothing);
  });

  testWidgets('semantics announce the heading, step, and exits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());

    expect(find.bySemanticsLabel('KNOW EVERY WORD'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel('SKIP'), findsOneWidget);
    expect(find.bySemanticsLabel('CREATE ACCOUNT'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('remains usable at 320 pixels and enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(textScale: 1.8));
    await tester.pumpAndSettle();

    final body = find.text(
      'Find chants by club or player. Save the ones you need for matchday.',
    );
    final bodyTopBefore = tester.getTopLeft(body).dy;

    await tester.drag(
      find.byKey(const Key('first-run-page-scroll-1')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(body).dy, lessThan(bodyTopBefore));
    expect(find.byKey(const Key('first-run-create-account')), findsOneWidget);
    expect(find.byKey(const Key('first-run-primary-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
