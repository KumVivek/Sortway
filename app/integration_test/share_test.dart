import 'package:flow_solver/flow_solver.dart';
import 'package:flow_sort/app.dart';
import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/features/play/play_sheets.dart';
import 'package:flow_sort/game/flow_game.dart';
import 'package:flow_sort/game/session_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// Wins level 1 with in-memory player data, taps Share, and leaves the real
/// system share sheet open for a while so it can be inspected:
///   flutter test integration_test/share_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, int ms) async {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: ms)),
    );
    await tester.pump();
  }

  testWidgets('win level 1 and open the share sheet', (tester) async {
    final env = TestEnv(ageBand: AgeBand.adult, realShare: true);
    await env.init();
    await tester.pumpWidget(
      ProviderScope(overrides: env.overrides, child: const FlowSortApp()),
    );
    await wait(tester, 1500);
    await tester.tap(find.byKey(const Key('home-play')));
    await wait(tester, 1500);

    final c =
        tester
            .widget<GameWidget<FlowGame>>(find.byType(GameWidget<FlowGame>))
            .game!
            .controller;
    final solution = solve(c.level);
    for (var i = 0; i < solution.optimalPath.length; i++) {
      for (final id in solution.optimalPath[i]) {
        c.flip(id);
      }
      while (c.state.nextItemIndex <= i) {
        await wait(tester, 100);
      }
    }
    expect(c.phase, PlayPhase.won);
    await wait(tester, 2500);
    expect(find.byType(WinSheet), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('win-share')));
    await wait(tester, 500);
    await tester.tap(find.byKey(const Key('win-share')));
    // Time to look at (and screenshot) the system share sheet.
    await wait(tester, 30000);
    expect(tester.takeException(), isNull);
  });
}
