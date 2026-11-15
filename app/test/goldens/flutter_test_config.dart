import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests compare screens against PNGs in `goldens/`.
///
/// Text uses the test font (Ahem, solid boxes) on purpose: it renders the
/// same on macOS and Linux, so the reference images made on a Mac also pass
/// in CI. The goldens still catch layout, colour, spacing and overflow
/// changes. A small tolerance absorbs anti-aliasing differences between
/// platforms.
///
/// After an intended visual change, refresh the images with:
///   flutter test --update-goldens test/goldens
/// and look at the changed PNGs before committing them.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final previous = goldenFileComparator;
  if (previous is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(
      Uri.parse('${previous.basedir}placeholder_test.dart'),
    );
  }
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  /// Fraction of pixels allowed to differ.
  static const tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
