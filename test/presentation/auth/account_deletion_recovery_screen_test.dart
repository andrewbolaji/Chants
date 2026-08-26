import 'package:chants/app/theme.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/presentation/auth/account_deletion_recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

Widget app({
  required Future<void> Function() onRetry,
  Future<void> Function()? onSignOut,
  double textScale = 1,
  bool statusCheckFailed = false,
}) {
  return MaterialApp(
    theme: ChantTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: AccountDeletionRecoveryScreen(
      onRetry: onRetry,
      onSignOut: onSignOut ?? () async {},
      statusCheckFailed: statusCheckFailed,
    ),
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
  testWidgets('keeps retry available after another unconfirmed response', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        onRetry: () async {
          calls += 1;
          throw const AccountDeletionRequestUnconfirmedException(
            'response lost',
          );
        },
      ),
    );

    expect(find.text('REQUEST NOT CONFIRMED'), findsOneWidget);
    expect(find.textContaining('does not cancel it'), findsOneWidget);
    await tester.tap(find.text('TRY DELETION AGAIN'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.textContaining('still could not confirm'), findsOneWidget);
    expect(find.text('TRY DELETION AGAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status-check state fits 390 by 844 at 1.8 text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(onRetry: () async {}, textScale: 1.8, statusCheckFailed: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('STATUS CHECK NEEDED'), findsOneWidget);
    expect(find.text('CHECK AGAIN'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-out failure keeps a truthful separate retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        onRetry: () async {},
        onSignOut: () async => throw StateError('offline'),
      ),
    );

    await tester.tap(find.text('SIGN OUT'));
    await tester.pumpAndSettle();

    expect(find.text('Could not sign out. Try again.'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
  });

  testWidgets('unknown deletion recovery visual at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/account_deletion_recovery_screen_test.dart',
      ),
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(onRetry: () async {}));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/account_deletion_recovery.png'),
    );
  });
}
