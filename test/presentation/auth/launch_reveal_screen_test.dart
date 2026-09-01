import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/launch_reveal_screen.dart';

void main() {
  Widget wrap({
    bool reduceMotion = false,
    bool showProgress = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: ChantTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: LaunchRevealScreen(showProgress: showProgress),
      ),
    );
  }

  testWidgets('reveals CHANTS once from the native launch frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());

    expect(
      find.bySemanticsLabel('Chants. Find your voice in the crowd.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('launch-letter-5')))
          .opacity,
      0,
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('launch-letter-5')))
          .opacity,
      greaterThan(0),
    );

    await tester.pumpAndSettle();
    for (var index = 0; index < 6; index++) {
      expect(
        tester
            .widget<Opacity>(find.byKey(ValueKey('launch-letter-$index')))
            .opacity,
        1,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion renders the final launch state immediately', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(reduceMotion: true));

    for (var index = 0; index < 6; index++) {
      expect(
        tester
            .widget<Opacity>(find.byKey(ValueKey('launch-letter-$index')))
            .opacity,
        1,
      );
    }
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('adapts to compact landscape and enlarged text', (tester) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(textScale: 1.5));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('launch-reveal-word')), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(wrap(textScale: 1.5));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('launch-reveal-word')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an honest busy cue while account state is unresolved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(reduceMotion: true, showProgress: true));

    expect(find.text('GETTING THINGS READY'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel('Chants. Getting things ready.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps unresolved progress inside compact landscape at 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(reduceMotion: true, showProgress: true, textScale: 2),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('GETTING THINGS READY'), findsNothing);
    expect(
      find.bySemanticsLabel('Chants. Getting things ready.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps unresolved progress inside a short enlarged portrait', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(reduceMotion: true, showProgress: true, textScale: 1.5),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('GETTING THINGS READY'), findsNothing);
    expect(
      find.bySemanticsLabel('Chants. Getting things ready.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
