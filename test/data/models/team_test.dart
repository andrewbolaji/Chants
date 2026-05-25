import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/team.dart';

void main() {
  group('Team', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'sportId': 's1',
        'competitionId': 'c1',
        'name': 'Arsenal',
        'crestImageUrl': 'https://example.com/crest.png',
      };
      final team = Team.fromJson(json, id: 't1');

      expect(team.id, 't1');
      expect(team.name, 'Arsenal');
      expect(team.crestImageUrl, 'https://example.com/crest.png');

      final output = team.toJson();
      expect(output['name'], 'Arsenal');
      expect(output.containsKey('id'), false);
    });

    test('nullable crestImageUrl', () {
      final json = {
        'sportId': 's1',
        'competitionId': 'c1',
        'name': 'Chelsea',
        'crestImageUrl': null,
      };
      final team = Team.fromJson(json, id: 't2');
      expect(team.crestImageUrl, isNull);
    });
  });
}
