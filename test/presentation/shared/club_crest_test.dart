import 'dart:ui' as ui;

import 'package:chants/app/theme.dart';
import 'package:chants/presentation/shared/club_crest.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ChantTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('uses a reviewed local asset with club semantics', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const ClubCrest(teamId: 'arsenal', clubName: 'Arsenal')),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Arsenal club badge'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    expect(resized.width, 44);
    expect(resized.height, isNull);
    expect(
      (resized.imageProvider as AssetImage).assetName,
      'assets/clubs/crests/arsenal.png',
    );
  });

  testWidgets('preserves a tall crest aspect ratio at DPR 2', (tester) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const ClubCrest(teamId: 'liverpool', clubName: 'Liverpool')),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    expect(resized.width, 88);
    expect(resized.height, isNull);

    final decoded = await tester.runAsync(() async {
      final data = await rootBundle.load('assets/clubs/crests/liverpool.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: resized.width!,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
    expect(decoded, isNotNull);
    expect(decoded!.width / decoded.height, closeTo(78 / 150, 0.01));
    decoded.dispose();
  });

  testWidgets('missing artwork fails soft to the Chants shield', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ClubCrest(
          teamId: 'missing-club',
          clubName: 'Missing Club',
          assetPathOverride: 'assets/clubs/crests/missing-club.png',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Missing Club club badge'), findsOneWidget);
    expect(find.byKey(const ValueKey('club-crest-fallback')), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
