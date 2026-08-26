import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/models/vote.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:chants/presentation/browse/discovery_section.dart';
import 'package:chants/presentation/browse/team_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'viewer-1';
}

class _ProfileRepository extends Mock implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) => Stream.value(null);
}

class _ChantRepository extends Mock implements ChantRepository {
  final browse = StreamController<ChantBrowseSnapshot>.broadcast();

  @override
  Stream<ChantBrowseSnapshot> teamBrowseStream({required String teamId}) {
    return browse.stream;
  }

  @override
  Stream<LiveChantSnapshot> chantStream(String id) =>
      Stream.value(const LiveChantSnapshot(chant: null, isFromCache: false));
}

class _PlayerRepository extends Mock implements PlayerRepository {
  @override
  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return Stream.value(const []);
  }
}

class _CommentRepository extends Mock implements CommentRepository {
  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return Stream.value(const []);
  }

  @override
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async => null;
}

class _VoteRepository extends Mock implements VoteRepository {
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async => null;
}

const _team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

final _chant = Chant(
  id: 'north-london-forever',
  title: 'North London Forever',
  sportId: _team.sportId,
  competitionId: _team.competitionId,
  teamId: _team.id,
  subjectTag: 'club',
  lyrics: 'North London forever',
  tuneName: 'The Angel',
  mediaType: 'none',
  status: 'canonical',
  chantType: 'sincere',
  createdBy: 'system',
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

final _savedClub = SavedClubSongbook(
  team: const SavedTeamIdentity(
    id: 'arsenal',
    sportId: 'football',
    competitionId: 'premier-league',
    name: 'Arsenal',
  ),
  savedAt: DateTime.utc(2026, 8, 22),
  refreshedAt: DateTime.utc(2026, 8, 22),
  chants: [SavedChantSnapshot.fromChant(_chant)],
);

void main() {
  testWidgets('signed-in home exposes the obvious Matchday Songbook entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
          discoveryProvider.overrideWith((ref) async => const []),
          allTeamsProvider.overrideWith((ref) => Stream.value(const {})),
        ],
        child: MaterialApp(theme: ChantTheme.dark, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MATCHDAY SONGBOOK'), findsOneWidget);
    expect(
      find.text('Saved on this device, ready when the signal drops.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });

  testWidgets('team save control distinguishes fresh, saved, and cache data', (
    tester,
  ) async {
    final repository = _ChantRepository();
    addTearDown(repository.browse.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          chantRepositoryProvider.overrideWithValue(repository),
          playerRepositoryProvider.overrideWithValue(_PlayerRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          savedSongbookProvider.overrideWith(
            (ref, uid) async =>
                SavedSongbook(clubSnapshots: {_team.id: _savedClub}),
          ),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          home: const TeamScreen(team: _team),
        ),
      ),
    );
    await tester.pump();
    repository.browse.add(ChantBrowseSnapshot(chants: [_chant]));
    await tester.pumpAndSettle();

    expect(find.text('REFRESH SAVED COPY'), findsOneWidget);
    final freshButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('REFRESH SAVED COPY'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(freshButton.onPressed, isNotNull);

    repository.browse.add(
      ChantBrowseSnapshot(chants: [_chant], isFromCache: true),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Connect for a fresh copy before saving.'),
      findsOneWidget,
    );
    final cachedButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('REFRESH SAVED COPY'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(cachedButton.onPressed, isNull);
  });

  testWidgets('live chant bookmark exposes explicit saved ownership', (
    tester,
  ) async {
    final repository = _ChantRepository();
    addTearDown(repository.browse.close);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          chantRepositoryProvider.overrideWithValue(repository),
          commentRepositoryProvider.overrideWithValue(_CommentRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
          userProfileProvider.overrideWith((ref, uid) => Stream.value(null)),
          blockedUserIdsProvider.overrideWith(
            (ref, uid) => Stream.value(const <String>{}),
          ),
          savedSongbookProvider.overrideWith(
            (ref, uid) async =>
                SavedSongbook(clubSnapshots: {_team.id: _savedClub}),
          ),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          home: ChantDetailScreen(chant: _chant, team: _team),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Saved with club'), findsOneWidget);
    expect(find.bySemanticsLabel('Saved with club'), findsOneWidget);
    semantics.dispose();
  });
}
