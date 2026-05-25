import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/chant_card.dart';

void main() {
  final testChant = Chant(
    id: 'ch1',
    title: 'Glory Glory',
    sportId: 's1',
    competitionId: 'c1',
    teamId: 't1',
    subjectTag: 'club',
    lyrics: 'Glory glory Man United\nAs the reds go marching on',
    tuneName: 'Battle Hymn',
    mediaType: 'none',
    status: 'canonical',
    realOrParody: 'real',
    createdBy: 'system',
    createdAt: DateTime(2026, 5, 24),
    updatedAt: DateTime(2026, 5, 24),
  );

  group('ChantCard', () {
    testWidgets('renders title and lyrics preview', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChantCard(
              chant: testChant,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Glory Glory'), findsOneWidget);
      expect(find.textContaining('Glory glory Man United'), findsOneWidget);
    });

    testWidgets('renders team name when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChantCard(
              chant: testChant,
              teamName: 'Manchester United',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Manchester United'), findsOneWidget);
    });

    testWidgets('shows canonical badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChantCard(
              chant: testChant,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Canonical'), findsOneWidget);
    });

    testWidgets('shows parody tag when applicable', (tester) async {
      final parodyChant = testChant.copyWith(realOrParody: 'parody');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChantCard(
              chant: parodyChant,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('parody'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChantCard(
              chant: testChant,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ChantCard));
      expect(tapped, true);
    });
  });
}
