import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

Future<void> _loadFonts() async {
  const fonts = {
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
    'Fraunces': 'assets/fonts/Fraunces-Variable.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  final cases = <({String name, Size size, String file})>[
    (
      name: 'standard phone',
      size: const Size(390, 844),
      file: 'onboarding_screen.png',
    ),
    (
      name: 'owner large phone',
      size: const Size(440, 956),
      file: 'onboarding_screen_large_phone.png',
    ),
  ];

  for (final testCase in cases) {
    testWidgets('onboarding form hierarchy on ${testCase.name}', (
      tester,
    ) async {
      installTolerantGoldenComparator(
        testFile: Uri.base.resolve(
          'test/presentation/auth/onboarding_screen_golden_test.dart',
        ),
        precisionTolerance: 0.018,
      );
      await _loadFonts();
      await tester.binding.setSurfaceSize(testCase.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ChantTheme.dark,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: OnboardingScreen(onDestinationSelected: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ENTER CHANTS'), findsOneWidget);
      expect(find.text('Community Rules'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${testCase.file}'),
      );
    });
  }
}
