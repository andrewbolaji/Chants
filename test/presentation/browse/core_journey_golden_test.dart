import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/models/vote.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/presentation/browse/competition_screen.dart';
import 'package:chants/presentation/browse/discovery_section.dart';
import 'package:chants/presentation/browse/player_screen.dart';
import 'package:chants/presentation/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'fan-1';
}

class _ProfileRepository extends Mock implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) => Stream.value(null);
}

class _TeamRepository extends Mock implements TeamRepository {
  @override
  Stream<List<Team>> teamsForCompetitionStream({
    required String competitionId,
  }) {
    return Stream.value(_teams);
  }
}

class _ChantRepository extends Mock implements ChantRepository {
  @override
  Stream<LiveChantSnapshot> chantStream(String id) => Stream.value(
    LiveChantSnapshot(
      chant: _chants.firstWhere((chant) => chant.id == id),
      isFromCache: false,
    ),
  );

  @override
  Stream<ChantBrowseSnapshot> playerBrowseStream({required String playerId}) {
    return Stream.value(
      ChantBrowseSnapshot(
        chants: _chants.where((chant) => chant.playerId == playerId).toList(),
      ),
    );
  }
}

class _VoteRepository extends Mock implements VoteRepository {
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async => null;
}

const _teams = [
  Team(
    id: 'arsenal',
    sportId: 'football',
    competitionId: 'premier-league',
    name: 'Arsenal',
  ),
  Team(
    id: 'aston-villa',
    sportId: 'football',
    competitionId: 'premier-league',
    name: 'Aston Villa',
  ),
  Team(
    id: 'brighton',
    sportId: 'football',
    competitionId: 'premier-league',
    name: 'Brighton & Hove Albion',
  ),
  Team(
    id: 'fulham',
    sportId: 'football',
    competitionId: 'premier-league',
    name: 'Fulham',
  ),
];

const _player = Player(id: 'saka', teamId: 'arsenal', name: 'Bukayo Saka');

final _chants = [
  Chant(
    id: 'north-london-forever',
    title: 'North London Forever',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'club',
    lyrics: 'We sing it loud from the North Bank every week',
    tuneName: 'The Angel (Louis Dunford)',
    mediaType: 'none',
    status: 'canonical',
    chantType: 'sincere',
    score: 42,
    commentCount: 12,
    createdBy: 'system',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  ),
  Chant(
    id: 'saka-running',
    title: 'Saka Running Down The Wing',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    playerId: 'saka',
    subjectTag: 'player',
    lyrics: 'We sing it loud from the North Bank every week',
    tuneName: 'Traditional terrace tune',
    mediaType: 'none',
    status: 'canonical',
    chantType: 'sincere',
    score: 31,
    commentCount: 8,
    createdBy: 'system',
    createdAt: DateTime.utc(2026, 8, 2),
    updatedAt: DateTime.utc(2026, 8, 2),
  ),
  Chant(
    id: 'super-saka-weekly',
    title: 'Super Saka Every Week',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    playerId: 'saka',
    subjectTag: 'player',
    lyrics: 'A new idea for the next matchday',
    tuneName: 'Original terrace idea',
    mediaType: 'none',
    status: 'community',
    chantType: 'sincere',
    origin: ChantOrigin.originalIdea,
    score: 7,
    commentCount: 4,
    createdBy: 'fan-1',
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  ),
];

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

Widget _app(
  Widget home, {
  ValueChanged<RouteSettings>? onRoute,
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ChantTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
    onGenerateRoute: (settings) {
      onRoute?.call(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: Text('DESTINATION')),
      );
    },
  );
}

void main() {
  testWidgets('Home search clear control is labelled and clears the query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          chantRepositoryProvider.overrideWithValue(_ChantRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          discoveryProvider.overrideWith((ref) async => [_chants.first]),
          allTeamsProvider.overrideWith(
            (ref) =>
                Stream.value({for (final team in _teams) team.id: team.name}),
          ),
        ],
        child: _app(const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MATCHDAY SONGBOOK'), findsNothing);
    expect(find.text('THE TERRACES, IN YOUR POCKET.'), findsOneWidget);
    expect(find.text('PREMIER LEAGUE'), findsOneWidget);
    expect(find.text('TERRACE PROVEN'), findsWidgets);
    expect(find.text('CHANT LAB'), findsOneWidget);
    expect(find.text('View all'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.enterText(find.byType(TextField), 'Arsenal');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(find.text('SEARCH RESULTS'), findsOneWidget);
    expect(find.text('NORTH LONDON FOREVER'), findsOneWidget);
    expect(find.text('PREMIER LEAGUE'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
    expect(find.text('TERRACE PROVEN'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'no matching chant');
    await tester.pumpAndSettle();
    expect(find.text('NOTHING MATCHES THAT'), findsOneWidget);
  });

  testWidgets('Home loading and error states promise only a real retry', (
    tester,
  ) async {
    final discovery = Completer<List<Chant>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          discoveryProvider.overrideWith((ref) => discovery.future),
          allTeamsProvider.overrideWith((ref) => Stream.value(const {})),
        ],
        child: _app(const HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    discovery.completeError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load chants. Try again.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'TRY AGAIN'), findsOneWidget);
    expect(find.textContaining('Pull down'), findsNothing);
  });

  testWidgets('Home actions keep the existing real routes', (tester) async {
    final visited = <RouteSettings>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
          chantRepositoryProvider.overrideWithValue(_ChantRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          discoveryProvider.overrideWith((ref) async => _chants),
          allTeamsProvider.overrideWith(
            (ref) =>
                Stream.value({for (final team in _teams) team.id: team.name}),
          ),
        ],
        child: _app(const HomeScreen(), onRoute: visited.add),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MATCHDAY SONGBOOK'));
    await tester.pumpAndSettle();
    expect(visited.last.name, AppRouter.savedSongbook);
    expect(visited.last.arguments, 'fan-1');
    Navigator.of(tester.element(find.text('DESTINATION'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('PREMIER LEAGUE'));
    await tester.pumpAndSettle();
    expect(visited.last.name, AppRouter.competition);
    expect(visited.last.arguments, const {
      'id': 'premier-league',
      'name': 'Premier League',
    });
    Navigator.of(tester.element(find.text('DESTINATION'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('NORTH LONDON FOREVER'));
    await tester.tap(find.text('NORTH LONDON FOREVER'));
    await tester.pumpAndSettle();
    expect(visited.last.name, AppRouter.chantDetail);
    expect(visited.last.arguments, isA<ChantDetailRouteArguments>());
    Navigator.of(tester.element(find.text('DESTINATION'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account and settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();
    expect(visited.last.name, AppRouter.feedback);
  });

  testWidgets('Home hierarchy remains scrollable at enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
          chantRepositoryProvider.overrideWithValue(_ChantRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          discoveryProvider.overrideWith((ref) async => _chants),
          allTeamsProvider.overrideWith(
            (ref) =>
                Stream.value({for (final team in _teams) team.id: team.name}),
          ),
        ],
        child: _app(const HomeScreen(), textScale: 1.8),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Account and settings'), findsOneWidget);
    expect(find.text('MATCHDAY SONGBOOK'), findsOneWidget);
    expect(find.text('PREMIER LEAGUE'), findsOneWidget);
    await tester.ensureVisible(find.text('CHANT LAB'));
    expect(find.text('SUPER SAKA EVERY WEEK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core Home, competition, and player baselines at 390 by 844', (
    tester,
  ) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/browse/core_journey_golden_test.dart',
      ),
      precisionTolerance: 0.022,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
          chantRepositoryProvider.overrideWithValue(_ChantRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          discoveryProvider.overrideWith((ref) async => _chants),
          allTeamsProvider.overrideWith(
            (ref) =>
                Stream.value({for (final team in _teams) team.id: team.name}),
          ),
        ],
        child: _app(const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/core_home.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamRepositoryProvider.overrideWithValue(_TeamRepository()),
        ],
        child: _app(
          const CompetitionScreen(
            competitionId: 'premier-league',
            competitionName: 'Premier League',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final competitionChevrons = find.byIcon(Icons.chevron_right);
    expect(competitionChevrons, findsNWidgets(4));
    final trailingX = tester.getTopLeft(competitionChevrons.first).dx;
    for (var index = 1; index < 4; index++) {
      expect(tester.getTopLeft(competitionChevrons.at(index)).dx, trailingX);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/core_competition.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          chantRepositoryProvider.overrideWithValue(_ChantRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
        ],
        child: _app(
          const PlayerScreen(
            player: _player,
            sportId: 'football',
            competitionId: 'premier-league',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/core_player.png'),
    );
  });
}
