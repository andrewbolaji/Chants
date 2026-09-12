import 'package:chants/data/services/performance_media_selection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingImagePicker extends ImagePicker {
  int recoveryCalls = 0;

  @override
  Future<LostDataResponse> retrieveLostData() async {
    recoveryCalls += 1;
    return LostDataResponse.empty();
  }
}

void main() {
  test('lost-data recovery is skipped on unsupported platforms', () async {
    final picker = _TrackingImagePicker();
    final selector = PerformanceMediaSelector(
      picker: picker,
      supportsLostDataRecovery: false,
    );

    expect(await selector.recoverInterruptedSelection(), isNull);
    expect(picker.recoveryCalls, 0);
  });

  test('lost-data recovery is consulted on Android', () async {
    final picker = _TrackingImagePicker();
    final selector = PerformanceMediaSelector(
      picker: picker,
      supportsLostDataRecovery: true,
    );

    expect(await selector.recoverInterruptedSelection(), isNull);
    expect(picker.recoveryCalls, 1);
  });
}
