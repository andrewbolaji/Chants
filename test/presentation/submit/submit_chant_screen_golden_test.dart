import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/presentation/submit/submit_chant_screen.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _GoldenUser extends Mock implements User {
  @override
  String get uid => 'viewer';
}

class _GoldenPlayerRepository implements PlayerRepository {
  @override
  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  testWidgets('origin-aware chant submission visual', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/submit/submit_chant_screen_golden_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_GoldenUser() as User?),
          ),
          playerRepositoryProvider.overrideWithValue(_GoldenPlayerRepository()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: const SubmitChantScreen(
            teamId: 'arsenal',
            sportId: 'football',
            competitionId: 'premier-league',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Already sung'), findsOneWidget);
    expect(find.text('I made this'), findsOneWidget);
    expect(
      find.text('Tell fans whether you heard it or made it.'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/submit_chant_origin.png'),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('chant-evidence-field')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Evidence link (optional)'), findsOneWidget);
    expect(
      find.text('Opens outside Chants. We do not host the video.'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/submit_chant_evidence.png'),
    );
  });

  testWidgets('missing prefilled Player recovery visual', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/submit/submit_chant_screen_golden_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_GoldenUser() as User?),
          ),
          playerRepositoryProvider.overrideWithValue(_GoldenPlayerRepository()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: const SubmitChantScreen(
            teamId: 'arsenal',
            sportId: 'football',
            competitionId: 'premier-league',
            prefilledPlayerId: 'former-player',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('player-selection-notice')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('player-selection-notice')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/submit_chant_stale_player.png'),
    );
  });
}
