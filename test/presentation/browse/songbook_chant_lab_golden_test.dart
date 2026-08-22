import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/presentation/browse/team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _GoldenChantRepository extends Mock implements ChantRepository {
  @override
  Stream<ChantBrowseSnapshot> teamBrowseStream({required String teamId}) {
    final recent = DateTime.now().subtract(const Duration(days: 1));
    return Stream.value(
      ChantBrowseSnapshot(
        chants: [
          _chant(
            id: 'north-london-forever',
            title: 'North London Forever',
            status: 'canonical',
            score: 42,
            createdAt: DateTime(2024, 1, 1),
          ),
          _chant(
            id: 'saka-song',
            title: 'Saka Running Down The Wing',
            status: 'canonical',
            score: 31,
            playerId: 'saka',
            createdAt: DateTime(2024, 2, 1),
          ),
          _chant(
            id: 'new-idea',
            title: 'Super Saka Every Week',
            status: 'community',
            score: 7,
            playerId: 'saka',
            createdAt: recent,
          ),
          _chant(
            id: 'second-idea',
            title: 'North Bank Noise',
            status: 'community',
            score: 1,
            createdAt: recent.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    );
  }
}

class _GoldenPlayerRepository extends Mock implements PlayerRepository {
  @override
  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return Stream.value(const [
      Player(id: 'saka', teamId: 'arsenal', name: 'Bukayo Saka'),
      Player(id: 'rice', teamId: 'arsenal', name: 'Declan Rice'),
    ]);
  }
}

const _team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

Chant _chant({
  required String id,
  required String title,
  required String status,
  required int score,
  required DateTime createdAt,
  String? playerId,
}) {
  return Chant(
    id: id,
    title: title,
    sportId: _team.sportId,
    competitionId: _team.competitionId,
    teamId: _team.id,
    playerId: playerId,
    subjectTag: playerId == null ? 'club' : 'player',
    lyrics: 'We sing it loud from the North Bank every week',
    tuneName: 'Traditional terrace tune',
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    score: score,
    commentCount: status == 'community' ? 4 : 12,
    createdBy: status == 'community' ? 'fan-1' : 'system',
    createdAt: createdAt,
    updatedAt: createdAt,
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
  testWidgets('Songbook and Chant Lab team surfaces at 390 by 844', (
    tester,
  ) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/browse/songbook_chant_lab_golden_test.dart',
      ),
      // Ubuntu Flutter 3.47.1 differs from the inspected macOS 3.44.8
      // baselines by at most 2.09% across these text-heavy full screens.
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          chantRepositoryProvider.overrideWithValue(_GoldenChantRepository()),
          playerRepositoryProvider.overrideWithValue(_GoldenPlayerRepository()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: const TeamScreen(team: _team),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/team_songbook.png'),
    );

    await tester.tap(find.text('CHANT LAB'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('ARSENAL')).top, greaterThanOrEqualTo(0));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/team_chant_lab.png'),
    );
  });
}
