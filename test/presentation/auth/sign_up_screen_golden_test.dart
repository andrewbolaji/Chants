import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/sign_up_screen.dart';
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
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  testWidgets('account creation hierarchy on owner large phone', (
    tester,
  ) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/sign_up_screen_golden_test.dart',
      ),
      precisionTolerance: 0.018,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: const SignUpScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JOIN THE TERRACE'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsNWidgets(2));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sign_up_screen_large_phone.png'),
    );
  });
}
