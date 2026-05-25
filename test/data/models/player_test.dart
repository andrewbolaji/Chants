import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/player.dart';

void main() {
  group('Player', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'teamId': 't1',
        'name': 'Bukayo Saka',
        'position': 'RW',
      };
      final player = Player.fromJson(json, id: 'p1');

      expect(player.id, 'p1');
      expect(player.name, 'Bukayo Saka');
      expect(player.position, 'RW');

      final output = player.toJson();
      expect(output['teamId'], 't1');
      expect(output['name'], 'Bukayo Saka');
      expect(output.containsKey('id'), false);
    });
  });
}
