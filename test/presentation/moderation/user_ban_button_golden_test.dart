import 'package:chants/app/spacing.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/presentation/moderation/user_ban_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  testWidgets('operator ban and unban controls visual', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/moderation/user_ban_button_golden_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ChantTheme.dark,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ACTIVE ACCOUNT',
                  style: ChantTheme.dark.textTheme.labelMedium,
                ),
                const SizedBox(height: Spacing.sm),
                UserBanButton(banned: false, onBan: () {}, onUnban: () {}),
                const SizedBox(height: Spacing.xl),
                Text(
                  'BANNED ACCOUNT',
                  style: ChantTheme.dark.textTheme.labelMedium,
                ),
                const SizedBox(height: Spacing.sm),
                UserBanButton(banned: true, onBan: () {}, onUnban: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ban'), findsOneWidget);
    expect(find.text('Unban'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/user_ban_button.png'),
    );
  });
}
