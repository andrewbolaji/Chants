import 'package:chants/data/models/performance_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes the server-owned cleanup retry state', () {
    expect(
      PerformanceDraftState.fromFirestore('cleanup_pending'),
      PerformanceDraftState.cleanupPending,
    );
  });

  test('unknown draft state still fails closed', () {
    expect(PerformanceDraftState.fromFirestore('unknown'), isNull);
  });
}
