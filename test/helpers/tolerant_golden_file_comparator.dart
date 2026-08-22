import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allows small renderer differences while still failing meaningful visual
/// regressions.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         0 <= precisionTolerance && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Installs the bounded comparator for one test and restores the previous
/// process-wide comparator during teardown.
void installTolerantGoldenComparator({
  required Uri testFile,
  double precisionTolerance = 0.015,
}) {
  final previousComparator = goldenFileComparator;
  goldenFileComparator = TolerantGoldenFileComparator(
    testFile,
    precisionTolerance: precisionTolerance,
  );
  addTearDown(() => goldenFileComparator = previousComparator);
}
