import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/launch_reveal_screen.dart';

void main() {
  Widget wrap({bool reduceMotion = false}) {
    return MaterialApp(
      theme: ChantTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const LaunchRevealScreen(),
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
}
