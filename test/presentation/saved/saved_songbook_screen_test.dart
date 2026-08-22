import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/services/saved_songbook_service.dart';
import 'package:chants/presentation/comments/comment_section.dart';
import 'package:chants/presentation/saved/saved_chant_detail_screen.dart';
import 'package:chants/presentation/saved/saved_club_screen.dart';
import 'package:chants/presentation/saved/saved_songbook_screen.dart';
import 'package:chants/presentation/shared/vote_controls.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  final String id;

  _User(this.id);

  @override
  String get uid => id;
}

class _FailingSavedSongbookService extends Mock
    implements SavedSongbookService {
  @override
  Future<SavedSongbookMutationResult> refreshClub({
    required String uid,
    required String teamId,
  }) async {
    throw StateError('offline');
  }
}

const _uid = 'viewer-1';
const _team = SavedTeamIdentity(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);
final _timestamp = DateTime.utc(2026, 8, 22, 12);

SavedChantSnapshot _chant({
  required String id,
  required String title,
  String status = 'canonical',
}) {
  return SavedChantSnapshot(
    id: id,
    teamId: _team.id,
    subjectTag: 'club',
    title: title,
    lyrics: 'We sing $title\nAll the way to the ground',
    tuneName: 'Traditional terrace tune',
    contextNotes: 'Saved context for matchday.',
    status: status,
    origin: status == 'community' ? ChantOrigin.originalIdea : null,
    createdAt: _timestamp,
    updatedAt: _timestamp,
    variations: const [
      ChantVariation(label: 'Away version', lyric: 'We sing it on the road'),
    ],
  );
}

SavedSongbook _songbook() {
  final covered = _chant(
    id: 'north-london-forever',
    title: 'North London Forever',
  );
  final individual = _chant(
    id: 'new-idea',
    title: 'North Bank Idea',
    status: 'community',
  );
  return SavedSongbook(
    clubSnapshots: {
      _team.id: SavedClubSongbook(
        team: _team,
        savedAt: _timestamp,
        refreshedAt: _timestamp,
        chants: [covered],
      ),
    },
    individualSnapshots: {
      covered.id: SavedIndividualChant(
        team: _team,
        savedAt: _timestamp,
        refreshedAt: _timestamp,
        chant: covered,
      ),
      individual.id: SavedIndividualChant(
        team: _team,
        savedAt: _timestamp,
        refreshedAt: _timestamp,
        chant: individual,
      ),
    },
  );
}

Widget _wrap(
  Widget child, {
  Future<SavedSongbook> Function()? load,
  double textScale = 1,
  String authUid = _uid,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(_User(authUid) as User?),
      ),
      savedSongbookProvider.overrideWith(
        (ref, uid) => load?.call() ?? Future.value(_songbook()),
      ),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: child,
    ),
  );
}

void main() {
  testWidgets('overview renders club ownership once and keeps unique saves', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SavedSongbookScreen(uid: _uid)));
    await tester.pumpAndSettle();

    expect(find.text('ARSENAL'), findsOneWidget);
    expect(find.textContaining('1 chant'), findsOneWidget);
    expect(find.text('NORTH LONDON FOREVER'), findsNothing);
    expect(find.text('NORTH BANK IDEA'), findsOneWidget);
    expect(find.text('SAVED CHANTS'), findsOneWidget);
  });

  testWidgets('future schema is preserved without a reset action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SavedSongbookScreen(uid: _uid),
        load: () => Future.error(const UnsupportedSavedSongbookVersion(2)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UPDATE CHANTS TO OPEN THIS COPY'), findsOneWidget);
    expect(find.text('RESET LOCAL COPY'), findsNothing);
  });

  testWidgets('a different signed-in UID cannot open the saved file', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const SavedSongbookScreen(uid: _uid), authUid: 'viewer-2'),
    );
    await tester.pumpAndSettle();

    expect(find.text('SAVED COPY LOCKED'), findsOneWidget);
    expect(find.text('ARSENAL'), findsNothing);
  });

  testWidgets('saved detail is local reading UI without live interactions', (
    tester,
  ) async {
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

    expect(find.text('NORTH LONDON FOREVER'), findsOneWidget);
    expect(find.textContaining('saved on this device'), findsOneWidget);
    expect(find.byType(VoteControls), findsNothing);
    expect(find.byType(CommentSection), findsNothing);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });

  testWidgets('failed club refresh keeps the complete local copy visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User(_uid) as User?),
          ),
          savedSongbookProvider.overrideWith((ref, uid) async => _songbook()),
          savedSongbookServiceProvider.overrideWithValue(
            _FailingSavedSongbookService(),
          ),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          home: const SavedClubScreen(uid: _uid, teamId: 'arsenal'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('REFRESH SAVED COPY'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not refresh. Your saved copy is still here.'),
      findsOneWidget,
    );
    expect(find.text('NORTH LONDON FOREVER'), findsOneWidget);
  });

  testWidgets('overview remains readable at enlarged text on 390 by 844', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(const SavedSongbookScreen(uid: _uid), textScale: 1.6),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MATCHDAY SONGBOOK'), findsOneWidget);
    expect(find.text('NORTH BANK IDEA'), findsOneWidget);
  });
}
