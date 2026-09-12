import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/auth_feature_config.dart';
import 'package:chants/data/repositories/auth_repository.dart';
import 'package:chants/presentation/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _AuthRepository extends Mock implements AuthRepository {}

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
  testWidgets('signed-out welcome carries the supporter shield', (
    tester,
  ) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/sign_in_screen_golden_test.dart',
      ),
      precisionTolerance: 0.018,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authFeatureConfigProvider.overrideWithValue(
            const AuthFeatureConfig(),
          ),
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: const SignInScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/icon/splash.png'),
        tester.element(find.byType(SignInScreen)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-supporter-mark')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('sign-in-supporter-mark'))).dx,
      lessThan(tester.getTopLeft(find.text('CHANTS')).dx),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sign_in_screen.png'),
    );
  });
}
