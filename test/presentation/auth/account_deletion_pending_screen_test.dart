import 'package:chants/app/theme.dart';
import 'package:chants/presentation/auth/account_deletion_pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

Widget app({required Future<void> Function() onSignOut, double textScale = 1}) {
  return MaterialApp(
    theme: ChantTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: AccountDeletionPendingScreen(onSignOut: onSignOut),
  );
}

Future<void> _loadFonts() async {
  final fonts = {
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'Anton': 'assets/fonts/Anton-Regular.ttf',
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
  testWidgets('contains content and recovers from sign-out failure', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        onSignOut: () async {
          calls += 1;
          throw StateError('offline');
        },
      ),
    );

    expect(find.text('DELETION IN PROGRESS'), findsOneWidget);
    expect(find.textContaining('safely queued'), findsOneWidget);
    expect(find.textContaining('private activity'), findsOneWidget);

    await tester.tap(find.text('SIGN OUT'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Could not sign out. Try again.'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a 390 by 844 viewport at 1.8 text scale', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(onSignOut: () async {}, textScale: 1.8));
    await tester.pumpAndSettle();

    expect(find.text('DELETION IN PROGRESS'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending state visual at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/account_deletion_pending_screen_test.dart',
      ),
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(onSignOut: () async {}));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/account_deletion_pending.png'),
    );
  });
}
