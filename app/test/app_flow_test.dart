import 'package:flame/game.dart';
import 'package:flow_core/flow_core.dart';
import 'package:flow_solver/flow_solver.dart';
import 'package:flow_sort/features/monetization/purchases_service.dart';
import 'package:flow_sort/features/onboarding/age_gate_screen.dart';
import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/features/play/play_sheets.dart';
import 'package:flow_sort/game/flow_game.dart';
import 'package:flow_sort/game/session_controller.dart';
import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

LevelSessionController controllerOf(WidgetTester tester) =>
    tester
        .widget<GameWidget<FlowGame>>(find.byType(GameWidget<FlowGame>))
        .game!
        .controller;

/// Plays the current level with the solver's mistake-free solution.
Future<void> playPerfectly(WidgetTester tester) async {
  final c = controllerOf(tester);
  final solution = solve(c.level, reactionBudget: c.level.meta.reactionBudget);
  expect(solution.perfect, isTrue);
  for (var i = 0; i < solution.optimalPath.length; i++) {
    for (final id in solution.optimalPath[i]) {
      c.flip(id);
    }
    var guard = 0;
    while (c.state.nextItemIndex <= i && guard++ < 400) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  expect(c.phase, PlayPhase.won);
  // Let the last item land and the result sheet slide in.
  await settle(tester, frames: 30);
}

/// Lets the belt run with no input until the level is lost.
Future<void> loseByDoingNothing(WidgetTester tester) async {
  final c = controllerOf(tester);
  var guard = 0;
  while (c.phase != PlayPhase.lost && guard++ < 600) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(c.phase, PlayPhase.lost);
  await settle(tester, frames: 30);
}

Future<void> pickYear(WidgetTester tester, int year) async {
  await tester.tap(find.byKey(const Key('birth-year')));
  await settle(tester);
  final item = find.text('$year');
  await tester.scrollUntilVisible(
    item,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(item);
  await settle(tester);
}

void main() {
  group('age check (plan section 8)', () {
    testWidgets('first launch asks, with nothing pre-selected', (tester) async {
      final env = TestEnv();
      await pumpApp(tester, env);
      expect(find.byType(AgeGateScreen), findsOneWidget);
      expect(find.text('Select a year'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('age-continue')),
      );
      expect(button.onPressed, isNull, reason: 'no default answer');
      expect(env.ads.policies, isEmpty, reason: 'no ad SDK before the answer');
      expect(env.analytics.events, isEmpty);
      expect(env.analytics.policies.last.analyticsEnabled, isFalse);
      await unmount(tester, env);
    });

    testWidgets('an adult year stores only the band and enables analytics', (
      tester,
    ) async {
      final env = TestEnv();
      await pumpApp(tester, env);
      await pickYear(tester, 1990);
      await tester.tap(find.byKey(const Key('age-continue')));
      await settle(tester);

      expect(find.byKey(const Key('home-play')), findsOneWidget);
      expect(env.settings.getString('age_band'), 'adult');
      expect(env.eventNames, ['age_check_done']);
      expect(env.analytics.policies.last.analyticsEnabled, isTrue);
      expect(env.ads.profile!.nonPersonalizedOnly, isFalse);
      expect(env.ads.profile!.tagForUnderAgeOfConsent, isFalse);
      await unmount(tester, env);
    });

    testWidgets('a minor year: restricted ads, analytics stays off', (
      tester,
    ) async {
      final env = TestEnv();
      await pumpApp(tester, env);
      await pickYear(tester, 2012);
      await tester.tap(find.byKey(const Key('age-continue')));
      await settle(tester);

      expect(env.settings.getString('age_band'), 'minor');
      expect(env.analytics.events, isEmpty);
      expect(env.analytics.policies.last.analyticsEnabled, isFalse);
      expect(env.analytics.policies.last.consentSignalsGranted, isFalse);
      final profile = env.ads.profile!;
      expect(profile.nonPersonalizedOnly, isTrue);
      expect(profile.tagForUnderAgeOfConsent, isTrue);
      expect(profile.maxAdContentRating, 'G');
      await unmount(tester, env);
    });

    testWidgets('skipping is treated as a minor', (tester) async {
      final env = TestEnv();
      await pumpApp(tester, env);
      await tester.tap(find.byKey(const Key('age-skip')));
      await settle(tester);

      expect(find.byKey(const Key('home-play')), findsOneWidget);
      expect(env.settings.getString('age_band'), 'unknown');
      expect(env.analytics.events, isEmpty);
      expect(env.ads.profile!.nonPersonalizedOnly, isTrue);
      await unmount(tester, env);
    });

    testWidgets('can be reset from Settings, which re-applies the policy', (
      tester,
    ) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);
      await tester.tap(find.byKey(const Key('home-settings')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('setting-age-reset')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('age-reset-confirm')));
      await settle(tester);

      expect(find.byType(AgeGateScreen), findsOneWidget);
      expect(env.settings.getString('age_band'), isNull);
      expect(env.analytics.policies.last.analyticsEnabled, isFalse);

      await tester.tap(find.byKey(const Key('age-skip')));
      await settle(tester);
      expect(env.ads.profile!.nonPersonalizedOnly, isTrue);
      await unmount(tester, env);
    });
  });

  group('playing', () {
    testWidgets('adult: win level 1, earn coins and a sticker, go to level 2', (
      tester,
    ) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);
      expect(find.text('Play · Level 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('home-play')));
      await settle(tester);
      expect(find.byType(GameWidget<FlowGame>), findsOneWidget);
      expect(find.textContaining('Tap the switch'), findsOneWidget);

      await playPerfectly(tester);
      expect(find.byType(WinSheet), findsOneWidget);
      expect(find.text('+40 coins'), findsOneWidget);
      expect(find.text('New sticker!'), findsOneWidget);
      expect(await env.store.coins(), 340);
      final progress = await env.store.progress();
      expect(progress['L001']!.stars, 3);
      expect(progress['L001']!.completed, isTrue);
      expect(await env.store.stickers(), hasLength(1));
      expect(await env.store.loadSnapshot(), isNull);
      expect(
        env.eventNames,
        containsAllInOrder([
          'level_start',
          'level_complete',
          'sticker_earned',
          'ad_offer_shown',
        ]),
      );

      // Rewarded "double coins", once.
      await tester.tap(find.byKey(const Key('double-coins')));
      await settle(tester);
      expect(await env.store.coins(), 380);
      expect(find.text('+80 coins'), findsOneWidget);
      expect(find.byKey(const Key('double-coins')), findsNothing);
      expect(env.eventNames, contains('ad_watched'));

      await tester.tap(find.byKey(const Key('win-next')));
      await settle(tester, frames: 20);
      expect(find.text('Level 2'), findsOneWidget);
      expect(env.ads.interstitialsShown, 0, reason: 'none before level 10');
      await unmount(tester, env);
    });

    testWidgets('minor: a full level sends no analytics at all', (
      tester,
    ) async {
      final env = TestEnv(ageBand: AgeBand.minor);
      await pumpApp(tester, env);
      await tester.tap(find.byKey(const Key('home-play')));
      await settle(tester);
      await playPerfectly(tester);
      expect(find.byType(WinSheet), findsOneWidget);
      expect(await env.store.coins(), 340);
      expect(env.analytics.events, isEmpty);
      await unmount(tester, env);
    });

    testWidgets(
      'losing offers undo / extra life, and a rewarded revive works',
      (tester) async {
        // Level 2 (r b b r r b r b) is lost mid-belt when nothing is flipped.
        final env = TestEnv(ageBand: AgeBand.adult);
        await env.init();
        await env.store.completeLevel(
          levelId: 'L001',
          stars: 3,
          flips: 1,
          coinsFor: (_, __) => 0,
        );
        await pumpApp(tester, env);
        expect(find.text('Play · Level 2'), findsOneWidget);
        await tester.tap(find.byKey(const Key('home-play')));
        await settle(tester);
        await loseByDoingNothing(tester);

        expect(find.byType(FailSheet), findsOneWidget);
        expect(find.text('Out of lives'), findsOneWidget);
        expect(env.eventNames, contains('level_fail'));
        final snap = await env.store.loadSnapshot();
        expect(snap!['ref'], 'campaign:L002', reason: 'survives an app kill');

        await tester.tap(find.byKey(const Key('fail-life-ad')));
        await settle(tester, frames: 20);
        final c = controllerOf(tester);
        expect(c.state.lives, 1);
        expect(c.phase, PlayPhase.countdown);
        expect(await env.store.coins(), 300, reason: 'the ad paid, not coins');
        expect(env.eventNames, containsAll(['ad_watched', 'booster_used']));

        // The rewarded extra life is once per level; coins still work. The
        // second loss is on the very last item, so the bought life wins it.
        await loseByDoingNothing(tester);
        expect(find.byKey(const Key('fail-life-ad')), findsNothing);
        expect(find.byKey(const Key('fail-undo-ad')), findsOneWidget);
        await tester.tap(find.byKey(const Key('fail-life-coins')));
        await settle(tester, frames: 40);
        expect(find.byType(WinSheet), findsOneWidget);
        expect(await env.store.coins(), 300 - 150 + 20);
        expect((await env.store.progress())['L002']!.stars, 1);
        await unmount(tester, env);
      },
    );

    testWidgets('boosters cost coins; pause sheet can quit', (tester) async {
      final env = TestEnv(ageBand: AgeBand.adult, startingCoins: 130);
      await pumpApp(tester, env);
      await tester.tap(find.byKey(const Key('home-play')));
      await settle(tester, frames: 70); // past the countdown

      await tester.tap(find.byKey(const Key('booster-slow')));
      await settle(tester);
      expect(await env.store.coins(), 10);
      expect(controllerOf(tester).state.slowTicksLeft, greaterThan(0));

      // Not enough for another, and "slow" has no ad alternative.
      await tester.tap(find.byKey(const Key('booster-slow')));
      await settle(tester);
      expect(find.text('Not enough coins'), findsOneWidget);
      expect(await env.store.coins(), 10);

      await tester.tap(find.byKey(const Key('pause')));
      await settle(tester);
      expect(controllerOf(tester).phase, PlayPhase.paused);
      await tester.tap(find.byKey(const Key('pause-quit')));
      await settle(tester, frames: 20);
      expect(find.byKey(const Key('home-play')), findsOneWidget);
      expect(env.eventNames, contains('level_quit'));
      expect(await env.store.loadSnapshot(), isNull);
      await unmount(tester, env);
    });

    testWidgets('an interrupted level can be resumed after a restart', (
      tester,
    ) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await env.init();
      final level = LevelDef.fromJson(
        (decodeLevelPack(
              await DefaultAssetBundle.of(
                tester.element(find.byType(View)),
              ).loadString('assets/levels/core_001.json'),
            ).levels[1])
            .toJson(),
      );
      final session = GameSession(level)..tick();
      await env.store.saveSnapshot({
        'ref': 'campaign:L002',
        'session': session.toJson(),
      });
      await pumpApp(tester, env);
      expect(find.text('Continue where you left off?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('resume-level')));
      await settle(tester, frames: 20);
      expect(find.text('Level 2'), findsOneWidget);
      expect(controllerOf(tester).state.nextItemIndex, 1);
      await unmount(tester, env);
    });
  });

  group('purchases', () {
    Future<void> openShop(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('home-shop')));
      await settle(tester);
    }

    testWidgets('minor: parental gate guards every purchase', (tester) async {
      final env = TestEnv(ageBand: AgeBand.minor);
      await pumpApp(tester, env);
      await openShop(tester);
      expect(find.text('Costs real money'), findsOneWidget);
      expect(find.text('₹89.00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('buy-coins_small')));
      await settle(tester);
      expect(find.text('Ask a grown-up'), findsOneWidget);
      expect(
        find.text('This purchase charges ₹89.00 of real money.'),
        findsOneWidget,
      );

      // Wrong answer: nothing is bought and a new question is asked.
      await tester.enterText(find.byKey(const Key('gate-answer')), '1');
      await tester.tap(find.byKey(const Key('gate-confirm')));
      await settle(tester);
      expect(find.text('That is not right. Try again.'), findsOneWidget);
      expect(env.purchases.purchased, isEmpty);

      final question =
          tester.widget<Text>(find.byKey(const Key('gate-question'))).data!;
      final numbers = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m[0]!));
      await tester.enterText(
        find.byKey(const Key('gate-answer')),
        '${numbers.first * numbers.last}',
      );
      await tester.tap(find.byKey(const Key('gate-confirm')));
      await settle(tester);
      expect(env.purchases.purchased, [ProductIds.coinsSmall]);
      expect(await env.store.coins(), 1300);
      expect(env.analytics.events, isEmpty);
      await unmount(tester, env);
    });

    testWidgets('adult: no gate; Remove Ads is owned afterwards', (
      tester,
    ) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);
      await openShop(tester);
      await tester.tap(find.byKey(const Key('buy-remove_ads')));
      await settle(tester);
      expect(find.text('Ask a grown-up'), findsNothing);
      expect(env.purchases.purchased, [ProductIds.removeAds]);
      expect(env.settings.getBool('remove_ads'), isTrue);
      expect(find.text('Owned'), findsOneWidget);
      expect(env.eventNames, containsAll(['iap_view', 'iap_purchase']));
      await unmount(tester, env);
    });

    testWidgets('a failed purchase grants nothing', (tester) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      env.purchases.outcome = PurchaseOutcome.failed;
      await pumpApp(tester, env);
      await openShop(tester);
      await tester.tap(find.byKey(const Key('buy-coins_small')));
      await settle(tester);
      expect(await env.store.coins(), 300);
      expect(find.textContaining('You were not charged'), findsOneWidget);
      await unmount(tester, env);
    });

    testWidgets('no store configured: the shop says so', (tester) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      env.purchases.available = false;
      await pumpApp(tester, env);
      await openShop(tester);
      expect(find.byKey(const Key('store-unavailable')), findsOneWidget);
      await unmount(tester, env);
    });
  });

  group('app shell', () {
    testWidgets('force update blocks the app', (tester) async {
      final env = TestEnv(
        ageBand: AgeBand.adult,
        remoteConfig: {RcKeys.forceUpdateMinVersion: '9.0.0'},
      );
      await pumpApp(tester, env);
      expect(find.text('Update needed'), findsOneWidget);
      expect(find.byKey(const Key('home-play')), findsNothing);
      await unmount(tester, env);
    });

    testWidgets('Hindi can be chosen in Settings', (tester) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);
      await tester.tap(find.byKey(const Key('home-settings')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('lang-hi')));
      await settle(tester);
      expect(find.text('सेटिंग्स'), findsOneWidget);
      expect(env.settings.getString('language'), 'hi');

      await tester.tap(find.byKey(const Key('setting-sound')));
      await settle(tester);
      expect(env.audio.soundOn, isFalse);
      expect(env.settings.getBool('sound_on'), isFalse);
      await unmount(tester, env);
    });

    testWidgets('map, album, daily and privacy screens open', (tester) async {
      final env = TestEnv(ageBand: AgeBand.adult);
      await pumpApp(tester, env);

      await tester.tap(find.byKey(const Key('home-map')));
      await settle(tester);
      expect(find.byKey(const Key('level-1')), findsOneWidget);
      expect(find.textContaining('Ocean Pals'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.byKey(const Key('home-album')));
      await settle(tester);
      expect(find.text('0/12'), findsWidgets);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.byKey(const Key('home-daily')));
      await settle(tester);
      expect(find.text('Reward: 100 coins'), findsOneWidget);
      expect(find.byKey(const Key('daily-streak')), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.byKey(const Key('home-settings')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('setting-privacy')));
      await settle(tester);
      for (final sdk in [
        'AdMob',
        'Firebase Analytics',
        'Crashlytics',
        'RevenueCat',
      ]) {
        final text = find.textContaining(sdk);
        await tester.scrollUntilVisible(
          text,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(text, findsOneWidget, reason: 'privacy page must list $sdk');
      }
      await unmount(tester, env);
    });
  });
}
