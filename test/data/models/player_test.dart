import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/player.dart';

void main() {
  group('Player', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'teamId': 't1',
        'name': 'Bukayo Saka',
      };
      final player = Player.fromJson(json, id: 'p1');

      expect(player.id, 'p1');
      expect(player.name, 'Bukayo Saka');
      expect(player.teamId, 't1');

      final output = player.toJson();
      expect(output['teamId'], 't1');
      expect(output['name'], 'Bukayo Saka');
      expect(output.containsKey('id'), false);
      expect(output.containsKey('position'), false);
    });

    test('copyWith', () {
      final player = Player(id: 'p1', teamId: 't1', name: 'Saka');
      final updated = player.copyWith(name: 'Odegaard');
      expect(updated.name, 'Odegaard');
      expect(updated.teamId, 't1');
    });
  });
}
