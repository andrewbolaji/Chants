import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/repositories/moderation_repository.dart';
import 'package:chants/presentation/auth/policy_acceptance_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _NoopModerationRepository implements ModerationRepository {
  @override
  Future<void> acceptPolicy() async {}
  @override
  Future<void> banUser(String userId) async {}
  @override
  Future<void> unbanUser(String userId) async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> demoteChant(String chantId) async {}
  @override
  Future<void> hideChant(String chantId) async {}
  @override
  Future<void> hideComment(String commentId) async {}
  @override
  Future<Map<String, dynamic>> mergeChants({
    required String sourceId,
    required String targetId,
  }) async => {};
  @override
  Future<void> promoteChant(String chantId) async {}
  @override
  Future<void> removeChant(String chantId) async {}
  @override
  Future<void> removeChantEvidence(String chantId) async {}
  @override
  Future<void> removeComment(String commentId) async {}
  @override
  Future<void> unhideChant(String chantId) async {}
  @override
  Future<void> unhideComment(String commentId) async {}
  @override
  Future<void> moderatePublishedPerformance({
    required String targetType,
    required String targetId,
    required String action,
  }) async {}
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
  testWidgets('current-policy gate visual at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/auth/launch_policy_golden_test.dart',
      ),
      // Linux and macOS render the bundled display fonts with different edge
      // antialiasing. The clean runner measured 2.05% with identical geometry;
      // keep this allowance local to the policy image.
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moderationRepositoryProvider.overrideWithValue(
            _NoopModerationRepository(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const PolicyAcceptanceGateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A QUICK RULES CHECK.'), findsOneWidget);
    expect(find.text('AGREE AND CONTINUE'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/policy_acceptance_gate.png'),
    );
  });
}
