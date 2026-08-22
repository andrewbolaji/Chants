import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/presentation/saved/saved_chant_detail_screen.dart';
import 'package:chants/presentation/saved/saved_songbook_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

const _uid = 'viewer-1';

class _User extends Mock implements User {
  @override
  String get uid => _uid;
}

const _team = SavedTeamIdentity(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);
final _refreshedAt = DateTime.utc(2026, 8, 22, 15, 30);

SavedChantSnapshot _chant({
  required String id,
  required String title,
  required String lyrics,
  String status = 'canonical',
}) {
  return SavedChantSnapshot(
    id: id,
    teamId: _team.id,
    subjectTag: 'club',
    title: title,
    lyrics: lyrics,
    tuneName: 'Traditional terrace tune',
    contextNotes: 'Sung before kick-off as the teams walk out.',
    status: status,
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2026, 8, 20),
    variations: const [
      ChantVariation(
        label: 'Away version',
        lyric: 'We sing it loud wherever we go',
      ),
    ],
  );
}

SavedSongbook _songbook() {
  final anthem = _chant(
    id: 'north-london-forever',
    title: 'North London Forever',
    lyrics:
        'North London forever\nWhatever the weather\nThese streets are our own',
  );
  final playerChant = _chant(
    id: 'saka-running-down-the-wing',
    title: 'Saka Running Down The Wing',
    lyrics: 'Saka running down the wing\nHear the North Bank sing',
  );
  final idea = _chant(
    id: 'north-bank-idea',
    title: 'North Bank Idea',
    lyrics: 'From the North Bank\nMake the whole ground sing',
    status: 'community',
  );
  return SavedSongbook(
    clubSnapshots: {
      _team.id: SavedClubSongbook(
        team: _team,
        savedAt: _refreshedAt,
        refreshedAt: _refreshedAt,
        chants: [anthem, playerChant],
      ),
    },
    individualSnapshots: {
      idea.id: SavedIndividualChant(
        team: _team,
        savedAt: _refreshedAt,
        refreshedAt: _refreshedAt,
        chant: idea,
      ),
    },
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

Widget _wrap(Widget home) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_User() as User?)),
      savedSongbookProvider.overrideWith((ref, uid) async => _songbook()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ChantTheme.dark,
      home: home,
    ),
  );
}

void main() {
  testWidgets('Saved Matchday Songbook overview and detail at 390 by 844', (
    tester,
  ) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/saved/saved_matchday_songbook_golden_test.dart',
      ),
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const SavedSongbookScreen(uid: _uid)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/saved_songbook_overview.png'),
    );

    await tester.pumpWidget(
      _wrap(
        const SavedChantDetailScreen(
          uid: _uid,
          chantId: 'north-london-forever',
          teamId: 'arsenal',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/saved_chant_detail.png'),
    );
  });
}
