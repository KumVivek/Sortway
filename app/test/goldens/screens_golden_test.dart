@Tags(['golden'])
library;

import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/features/play/play_sheets.dart';
import 'package:flow_sort/features/share/share_card.dart';
import 'package:flow_sort/ui/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_flow_test.dart' show loseByDoingNothing, playPerfectly;
import '../helpers.dart';

/// Screenshot tests for the main screens on a 390x844 phone. See
/// flutter_test_config.dart for why text shows as boxes.
void main() {
  Future<void> shot(WidgetTester tester, String name) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

  Future<void> open(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester, frames: 20);
  }

  testWidgets('age gate', (tester) async {
    final env = TestEnv();
    await pumpApp(tester, env);
    await shot(tester, 'age_gate');
    await unmount(tester, env);
  });

  testWidgets('home', (tester) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await shot(tester, 'home');
    await unmount(tester, env);
  });

  for (final (name, key) in [
    ('level_map', 'home-map'),
    ('daily', 'home-daily'),
    ('album', 'home-album'),
    ('shop', 'home-shop'),
    ('settings', 'home-settings'),
  ]) {
    testWidgets(name, (tester) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);
      await open(tester, key);
      await shot(tester, name);
      await unmount(tester, env);
    });
  }

  testWidgets('shop, minor (real-money labels)', (tester) async {
    final env = TestEnv(ageBand: AgeBand.minor);
    await pumpApp(tester, env);
    await open(tester, 'home-shop');
    await shot(tester, 'shop_minor');
    await unmount(tester, env);
  });

  testWidgets('play, level 1 start', (tester) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    await shot(tester, 'play_level1');
    await unmount(tester, env);
  });

  testWidgets('win sheet', (tester) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    await playPerfectly(tester);
    expect(find.byType(WinSheet), findsOneWidget);
    await shot(tester, 'win_sheet');
    await unmount(tester, env);
  });

  testWidgets('fail sheet', (tester) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    await loseByDoingNothing(tester);
    await shot(tester, 'fail_sheet');
    await unmount(tester, env);
  });

  testWidgets('share card', (tester) async {
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 270,
          height: 337.5,
          child: CustomPaint(
            painter: _Painter(
              (c, s) => paintShareCard(
                c,
                s,
                const ShareCardData(
                  appName: 'Flow Sort',
                  title: 'Level 12',
                  headline: 'Level complete!',
                  stars: 2,
                  tagline: 'Can you sort it faster?',
                  detail: '7 flips',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byType(CustomPaint).last, matchesGoldenFile('goldens/share_card.png'));
  });

  testWidgets('app icon', (tester) async {
    await tester.pumpWidget(
      Center(
        child: SizedBox.square(
          dimension: 256,
          child: CustomPaint(painter: _Painter(paintAppIcon)),
        ),
      ),
    );
    await expectLater(find.byType(CustomPaint).last, matchesGoldenFile('goldens/app_icon.png'));
  });
}

class _Painter extends CustomPainter {
  _Painter(this.paintFn);
  final void Function(Canvas, Size) paintFn;

  @override
  void paint(Canvas canvas, Size size) => paintFn(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
