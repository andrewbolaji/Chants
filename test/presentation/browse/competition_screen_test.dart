import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/presentation/browse/competition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _TeamRepository extends Mock implements TeamRepository {
  final controller = StreamController<List<Team>>.broadcast();

  @override
  Stream<List<Team>> teamsForCompetitionStream({
    required String competitionId,
  }) {
    return controller.stream;
  }
}

const _arsenal = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

const _villa = Team(
  id: 'aston-villa',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Aston Villa',
);

Widget _wrap(
  _TeamRepository repository, {
  ValueChanged<RouteSettings>? onRoute,
}) {
  return ProviderScope(
    overrides: [teamRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: const CompetitionScreen(
        competitionId: 'premier-league',
        competitionName: 'Premier League',
      ),
      onGenerateRoute: (settings) {
        onRoute?.call(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('DESTINATION')),
        );
      },
    ),
  );
}

void main() {
  testWidgets('sorts an immutable repository snapshot without mutating it', (
    tester,
  ) async {
    final repository = _TeamRepository();
    addTearDown(repository.controller.close);
    RouteSettings? navigatedRoute;

    await tester.pumpWidget(
      _wrap(repository, onRoute: (settings) => navigatedRoute = settings),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.controller.add(List.unmodifiable([_villa, _arsenal]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final chevrons = find.byIcon(Icons.chevron_right);
    expect(chevrons, findsNWidgets(2));
    expect(
      tester.getTopLeft(chevrons.at(0)).dx,
      tester.getTopLeft(chevrons.at(1)).dx,
    );
    expect(
      tester.getTopLeft(find.text('Arsenal')).dy,
      lessThan(tester.getTopLeft(find.text('Aston Villa')).dy),
    );

    await tester.tap(find.text('Arsenal'));
    await tester.pumpAndSettle();
    expect(navigatedRoute?.name, AppRouter.team);
    expect(navigatedRoute?.arguments, _arsenal);
  });

  testWidgets('error state gives recovery guidance the screen supports', (
    tester,
  ) async {
    final repository = _TeamRepository();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();
    repository.controller.addError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load clubs. Go back and try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Pull down'), findsNothing);
  });

  testWidgets('empty competition keeps navigation and explains the state', (
    tester,
  ) async {
    final repository = _TeamRepository();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();
    repository.controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('PREMIER LEAGUE'), findsOneWidget);
    expect(find.text('No clubs yet. Check back soon.'), findsOneWidget);
  });
}
