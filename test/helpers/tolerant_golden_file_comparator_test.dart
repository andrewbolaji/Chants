import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tolerant_golden_file_comparator.dart';

Future<Uint8List> _pngWithBlackPixels(int blackPixels) async {
  const size = 10;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawRect(
      const ui.Rect.fromLTWH(0, 0, 10, 10),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );

  for (var index = 0; index < blackPixels; index++) {
    canvas.drawRect(
      ui.Rect.fromLTWH(
        (index % size).toDouble(),
        (index ~/ size).toDouble(),
        1,
        1,
      ),
      ui.Paint()..color = const ui.Color(0xff000000),
    );
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden tolerance accepts renderer drift but rejects a regression',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'chants-golden-comparator-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));

      final comparator = TolerantGoldenFileComparator(
        temporaryDirectory.uri.resolve('comparator_test.dart'),
        precisionTolerance: 0.015,
      );
      final golden = Uri.parse('golden.png');
      final baseline = await _pngWithBlackPixels(0);
      await comparator.update(golden, baseline);

      expect(await comparator.compare(baseline, golden), isTrue);
      expect(
        await comparator.compare(await _pngWithBlackPixels(1), golden),
        isTrue,
      );
      await expectLater(
        comparator.compare(await _pngWithBlackPixels(100), golden),
        throwsA(isA<FlutterError>()),
      );
    },
  );
}
