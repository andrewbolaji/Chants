import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/first_run_orientation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

Future<void> _loadFonts() async {
  const fonts = {
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  testWidgets('first-run orientation hierarchy at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/first_run_orientation_golden_test.dart',
      ),
      // This full-screen, text-heavy surface uses the same bounded allowance
      // as the inspected authentication and policy presentation references.
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ChantTheme.dark,
        home: FirstRunOrientationScreen(
          onSkip: () async {},
          onContinue: () async {},
          onCreateAccount: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/first_run_orientation_songbook.png'),
    );

    await tester.tap(find.byKey(const Key('first-run-primary-action')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/first_run_orientation_chant_lab.png'),
    );

    await tester.tap(find.byKey(const Key('first-run-primary-action')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/first_run_orientation_stage.png'),
    );
  });
}
