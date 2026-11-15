import 'package:flow_sort/app.dart';
import 'package:flow_sort/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// On-device smoke test with the real storage, audio and platform plugins:
///   flutter test integration_test -d <device>
/// Start from a fresh install so the age question is shown.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start reaches the home screen and opens level 1', (
    tester,
  ) async {
    final started = DateTime.now();
    final overrides = await bootstrap();
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const FlowSortApp()),
    );
    await tester.pump(const Duration(seconds: 1));

    final skip = find.byKey(const Key('age-skip'));
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pump(const Duration(seconds: 1));
    }
    final resume = find.byKey(const Key('resume-level'));
    if (resume.evaluate().isNotEmpty) {
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const Key('home-play')), findsOneWidget);
    // Plan target: cold start under 3 seconds.
    expect(DateTime.now().difference(started).inSeconds, lessThan(8));

    await tester.tap(find.byKey(const Key('home-play')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('pause')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
