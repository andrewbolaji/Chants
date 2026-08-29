import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'forwards the typed target without exposing a private identifier',
    () async {
      final calls = <String>[];
      final repository = PublicShareRepository(
        resolver: (target, targetId) async {
          calls.add('${target.name}:$targetId');
          return Uri.parse('https://chantsfc.com/${target.name}/$targetId');
        },
      );

      final destination = await repository.resolve(
        PublicShareTarget.performance,
        'performance-1',
      );

      expect(calls, ['performance:performance-1']);
      expect(destination.host, 'chantsfc.com');
    },
  );
}
