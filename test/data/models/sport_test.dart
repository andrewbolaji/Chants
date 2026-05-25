import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/sport.dart';

void main() {
  group('Sport', () {
    test('fromJson and toJson round-trip', () {
      final json = {'name': 'Football', 'enabled': true};
      final sport = Sport.fromJson(json, id: 'sport1');

      expect(sport.id, 'sport1');
      expect(sport.name, 'Football');
      expect(sport.enabled, true);

      final output = sport.toJson();
      expect(output['name'], 'Football');
      expect(output['enabled'], true);
      expect(output.containsKey('id'), false);
    });

    test('disabled sport', () {
      final json = {'name': 'Cricket', 'enabled': false};
      final sport = Sport.fromJson(json, id: 's2');
      expect(sport.enabled, false);
    });

    test('copyWith', () {
      final sport = Sport(id: 's1', name: 'Football', enabled: true);
      final updated = sport.copyWith(enabled: false);
      expect(updated.enabled, false);
      expect(updated.name, 'Football');
    });
  });
}
