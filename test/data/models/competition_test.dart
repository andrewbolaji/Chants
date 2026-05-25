import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/competition.dart';

void main() {
  group('Competition', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'sportId': 's1',
        'name': 'Premier League',
        'enabled': true,
      };
      final comp = Competition.fromJson(json, id: 'c1');

      expect(comp.id, 'c1');
      expect(comp.sportId, 's1');
      expect(comp.name, 'Premier League');
      expect(comp.enabled, true);

      final output = comp.toJson();
      expect(output['sportId'], 's1');
      expect(output['name'], 'Premier League');
      expect(output['enabled'], true);
      expect(output.containsKey('id'), false);
    });

    test('copyWith', () {
      final comp = Competition(
        id: 'c1',
        sportId: 's1',
        name: 'PL',
        enabled: true,
      );
      final updated = comp.copyWith(name: 'La Liga');
      expect(updated.name, 'La Liga');
      expect(updated.sportId, 's1');
    });
  });
}
