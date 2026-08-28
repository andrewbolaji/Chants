import 'package:chants/presentation/feed/performance_video_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('qualifies at three seconds or at completion for a short clip', () {
    expect(
      isQualifiedPerformancePlayback(
        position: const Duration(milliseconds: 2999),
        completed: false,
      ),
      isFalse,
    );
    expect(
      isQualifiedPerformancePlayback(
        position: const Duration(seconds: 3),
        completed: false,
      ),
      isTrue,
    );
    expect(
      isQualifiedPerformancePlayback(
        position: const Duration(seconds: 1),
        completed: true,
      ),
      isTrue,
    );
  });
}
