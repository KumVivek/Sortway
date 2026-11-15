import 'package:flame/game.dart';
import 'package:flow_core/flow_core.dart';
import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/game/flow_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' show loseByDoingNothing, playPerfectly;
import 'helpers.dart';

/// Flutter's accessibility guidelines on every main screen: every tappable
/// thing has a label a screen reader can speak, tap targets are big enough,
/// and text has enough contrast.
void main() {
  Future<void> checkGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  Future<void> open(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester, frames: 20);
  }

  testWidgets('age gate', (tester) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv();
    await pumpApp(tester, env);
    await checkGuidelines(tester);
    await unmount(tester, env);
    handle.dispose();
  });

  testWidgets('home', (tester) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await checkGuidelines(tester);
    await unmount(tester, env);
    handle.dispose();
  });

  for (final key in [
    'home-map',
    'home-daily',
    'home-album',
    'home-shop',
    'home-settings',
  ]) {
    testWidgets(key, (tester) async {
      final handle = tester.ensureSemantics();
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);
      await open(tester, key);
      await checkGuidelines(tester);
      await unmount(tester, env);
      handle.dispose();
    });
  }

  testWidgets('play screen', (tester) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    await checkGuidelines(tester);
    await unmount(tester, env);
    handle.dispose();
  });

  testWidgets('win sheet', (tester) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    await playPerfectly(tester);
    await checkGuidelines(tester);
    await unmount(tester, env);
    handle.dispose();
  });

  testWidgets('fail sheet', (tester) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    await loseByDoingNothing(tester);
    await checkGuidelines(tester);
    await unmount(tester, env);
    handle.dispose();
  });

  testWidgets('the board can be read and played with a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    final c =
        tester
            .widget<GameWidget<FlowGame>>(find.byType(GameWidget<FlowGame>))
            .game!
            .controller;

    expect(
      find.bySemanticsLabel(
        'Game board. Next item: Red. 3 lives left. 6 items to sort.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Red bin, 0 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Blue bin, 0 of 3'), findsOneWidget);

    final sw = find.bySemanticsLabel('Switch 1, points left');
    expect(sw, findsOneWidget);
    expect(
      tester.getSemantics(sw),
      matchesSemantics(
        label: 'Switch 1, points left',
        isButton: true,
        hasTapAction: true,
        onTapHint: 'flip the switch',
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Switch 1, points left'));
    await settle(tester);
    expect(c.state.switches['s1'], SwitchDir.right);
    expect(find.bySemanticsLabel('Switch 1, points right'), findsOneWidget);

    await unmount(tester, env);
    handle.dispose();
  });

  testWidgets('touch play still reaches the board under the labels', (
    tester,
  ) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await open(tester, 'home-play');
    final game =
        tester
            .widget<GameWidget<FlowGame>>(find.byType(GameWidget<FlowGame>))
            .game!;
    final centre = game.layout.nodes['s1']!;
    final origin = tester.getTopLeft(find.byType(GameWidget<FlowGame>));
    await tester.tapAt(origin + centre);
    await settle(tester);
    expect(game.controller.state.switches['s1'], SwitchDir.right);
    await unmount(tester, env);
  });
}
