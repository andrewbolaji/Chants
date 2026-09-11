import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/launch_reveal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  testWidgets('launch reveal final frame at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/launch_reveal_golden_test.dart',
      ),
      precisionTolerance: 0.02,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ChantTheme.dark,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LaunchRevealScreen(animationDuration: Duration.zero),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/icon/splash.png'),
        tester.element(find.byType(LaunchRevealScreen)),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/launch_reveal.png'),
    );
  });
}
