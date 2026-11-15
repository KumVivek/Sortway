import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/features/play/play_sheets.dart';
import 'package:flow_sort/features/share/share_card.dart';
import 'package:flow_sort/features/share/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' show playPerfectly;
import 'helpers.dart';

const _card = ShareCardData(
  appName: 'Flow Sort',
  title: 'Level 12',
  headline: 'Level complete!',
  stars: 2,
  tagline: 'Can you sort it faster?',
  detail: '7 flips',
);

Future<void> _winLevelOne(WidgetTester tester, TestEnv env) async {
  await pumpApp(tester, env);
  await tester.tap(find.byKey(const Key('home-play')));
  await settle(tester);
  await playPerfectly(tester);
  expect(find.byType(WinSheet), findsOneWidget);
  await tester.ensureVisible(find.byKey(const Key('win-share')));
  await settle(tester);
}

void main() {
  test('only confirmed adults share without the parental gate', () {
    expect(const AgePolicy(AgeBand.adult).sharingNeedsGate, isFalse);
    for (final band in [AgeBand.minor, AgeBand.child, AgeBand.unknown]) {
      expect(AgePolicy(band).sharingNeedsGate, isTrue, reason: band.name);
    }
  });

  testWidgets('the card renders to a 1080x1350 PNG', (tester) async {
    final png = await tester.runAsync(() => renderShareCard(_card));
    expect(png, isNotNull);
    // PNG signature.
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final image = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png);
      return (await codec.getNextFrame()).image;
    });
    expect(image!.width, 1080);
    expect(image.height, 1350);
  });

  testWidgets('the card paints at any star count without errors', (
    tester,
  ) async {
    for (final stars in [0, 1, 3, 9]) {
      final recorder = ui.PictureRecorder();
      paintShareCard(
        Canvas(recorder),
        shareCardSize,
        ShareCardData(
          appName: 'Flow Sort',
          title: 'डेली चैलेंज',
          headline: 'लेवल पूरा!',
          stars: stars,
          tagline: 'x' * 200,
        ),
      );
      recorder.endRecording().dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('adult: Share sends the card and caption, and logs it', (
    tester,
  ) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await _winLevelOne(tester, env);
    await tester.tap(find.byKey(const Key('win-share')));
    await settle(tester);

    expect(find.text('Ask a grown-up'), findsNothing);
    expect(env.share.shared, hasLength(1));
    expect(
      env.share.shared.single.text,
      'I cleared Level 1 in Flow Sort with 3 of 3 stars! Can you beat that?',
    );
    final card = env.cards.single;
    expect(card.title, 'Level 1');
    expect(card.stars, 3);
    expect(card.detail, '1 flip');
    expect(env.eventNames, contains('level_share'));
    // The sheet is still there, so the player can carry on.
    expect(find.byKey(const Key('win-next')), findsOneWidget);
    await unmount(tester, env);
  });

  testWidgets(
    'minor: the parental gate comes first; cancelling shares nothing',
    (tester) async {
      final env = TestEnv(ageBand: AgeBand.minor);
      await _winLevelOne(tester, env);
      await tester.tap(find.byKey(const Key('win-share')));
      await settle(tester);

      expect(find.text('Ask a grown-up'), findsOneWidget);
      expect(
        find.text('Sharing opens another app outside the game.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(env.share.shared, isEmpty);

      // A correct answer lets it through.
      await tester.tap(find.byKey(const Key('win-share')));
      await settle(tester);
      final question =
          tester.widget<Text>(find.byKey(const Key('gate-question'))).data!;
      final n = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m[0]!));
      await tester.enterText(
        find.byKey(const Key('gate-answer')),
        '${n.first * n.last}',
      );
      await tester.tap(find.byKey(const Key('gate-confirm')));
      await settle(tester);
      expect(env.share.shared, hasLength(1));
      expect(env.analytics.events, isEmpty, reason: 'no analytics for minors');
      await unmount(tester, env);
    },
  );

  testWidgets('a share sheet that cannot open tells the player', (
    tester,
  ) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    env.share.available = false;
    await _winLevelOne(tester, env);
    await tester.tap(find.byKey(const Key('win-share')));
    await settle(tester);
    expect(find.text('Sharing is not available right now.'), findsOneWidget);
    expect(env.eventNames, isNot(contains('level_share')));
    await unmount(tester, env);
  });

  test('fake share service records and can be unavailable', () async {
    final s = FakeShareService();
    expect(await s.shareImage(Uint8List(1), text: 'a'), isTrue);
    s.available = false;
    expect(await s.shareImage(Uint8List(1), text: 'b'), isFalse);
    expect(s.shared.single.text, 'a');
  });
}
