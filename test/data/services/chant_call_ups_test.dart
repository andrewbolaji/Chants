import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/services/chant_call_ups.dart';
import 'package:flutter_test/flutter_test.dart';

Chant chantFor(String playerId, {String status = 'community'}) => Chant(
  id: 'chant-$playerId',
  title: 'Synthetic test chant',
  sportId: 'football',
  competitionId: 'test-league',
  teamId: 'test-club',
  playerId: playerId,
  subjectTag: 'player',
  lyrics: 'Synthetic fixture',
  tuneName: 'Test tune',
  mediaType: 'none',
  status: status,
  chantType: 'sincere',
  createdBy: 'test-user',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('any visible trust status covers the player, not just the Songbook', () {
    final players = [
      for (final id in ['proven', 'idea', 'future', 'uncovered'])
        Player(id: id, teamId: 'test-club', name: id),
    ];
    final result = chantCallUpPlayers(
      teamId: 'test-club',
      players: players,
      chants: [
        chantFor('proven', status: 'canonical'),
        chantFor('idea'),
        chantFor('future', status: 'future-status'),
      ],
    );
    expect(result.map((player) => player.id), ['uncovered']);
    expect(players.length, 4);
  });

  test(
    'filters invalid/other-club players and sorts name then ID without mutation',
    () {
      const players = [
        Player(id: 'z', teamId: 'test-club', name: 'Zed'),
        Player(id: 'b', teamId: 'test-club', name: 'Alex'),
        Player(id: 'a', teamId: 'test-club', name: 'alex'),
        Player(id: 'other', teamId: 'other-club', name: 'Aaron'),
        Player(id: '', teamId: 'test-club', name: 'No ID'),
        Player(id: 'blank', teamId: 'test-club', name: '  '),
      ];
      final result = chantCallUpPlayers(
        teamId: 'test-club',
        players: players,
        chants: [
          chantFor('a').copyWith(hidden: true),
          chantFor('b').copyWith(removed: true),
          chantFor('z').copyWith(teamId: 'other-club'),
        ],
      );
      expect(result.map((player) => player.id), ['a', 'b', 'z']);
      expect(players.first.id, 'z');
      expect(
        chantCallUpPlayers(teamId: 'test-club', players: [], chants: []),
        isEmpty,
      );
    },
  );
}
