import 'dart:math' as math;

import 'package:flow_sort/features/levels/level_ref.dart';
import 'package:flow_sort/features/meta/daily.dart';
import 'package:flow_sort/features/meta/stickers.dart';
import 'package:flow_sort/features/play/level_rewards.dart';
import 'package:flow_sort/services/database.dart';
import 'package:flow_sort/services/game_store.dart';
import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stickers', () {
    test('a set fills with twelve pulls and never repeats', () {
      final rng = math.Random(1);
      final owned = <StickerKey>{};
      for (var i = 0; i < stickersPerSet; i++) {
        final s = pullSticker(owned, rng);
        expect(s.set, 0);
        expect(owned.contains(s), isFalse, reason: 'duplicate on pull $i');
        expect(completesSet(owned, s), i == stickersPerSet - 1);
        owned.add(s);
      }
      expect(ownedInSet(owned, 0), stickersPerSet);
      expect(currentSetIndex(owned), 1);
      expect(pullSticker(owned, rng).set, 1);
    });

    test('set names exist in both languages and beyond the list', () {
      expect(stickerSets, hasLength(20));
      expect(stickerSetName(0, 'en'), 'Ocean Pals');
      expect(stickerSetName(0, 'hi'), isNot('Ocean Pals'));
      expect(stickerSetName(20, 'en'), 'Bonus Set 1');
      expect(stickerSetName(21, 'hi'), 'बोनस सेट 2');
    });
  });

  group('daily streak', () {
    test('counts consecutive days', () {
      expect(nextStreak(lastDay: 0, today: 20261114, streak: 0), 1);
      expect(nextStreak(lastDay: 20261114, today: 20261115, streak: 1), 2);
      expect(nextStreak(lastDay: 20261130, today: 20261201, streak: 5), 6);
      expect(nextStreak(lastDay: 20261231, today: 20270101, streak: 9), 10);
    });

    test('a missed day just restarts the count', () {
      expect(nextStreak(lastDay: 20261110, today: 20261114, streak: 7), 1);
    });

    test('replaying the same day changes nothing', () {
      expect(nextStreak(lastDay: 20261114, today: 20261114, streak: 4), 4);
    });

    test('shown streak', () {
      expect(shownStreak(lastDay: 0, today: 20261114, streak: 0), 0);
      expect(shownStreak(lastDay: 20261114, today: 20261114, streak: 3), 3);
      expect(shownStreak(lastDay: 20261113, today: 20261114, streak: 3), 3);
      expect(shownStreak(lastDay: 20261112, today: 20261114, streak: 3), 0);
    });

    test('tracker persists and rewards only the first win of a day', () async {
      final store = GameStore(AppDatabase.memory());
      final tracker = DailyTracker(store);
      final day1 = DateTime(2026, 11, 14, 9);
      expect((await tracker.status(day1)).doneToday, isFalse);
      expect(await tracker.complete(day1), (streak: 1, first: true));
      expect(await tracker.complete(day1), (streak: 1, first: false));
      final s = await tracker.status(day1);
      expect(s.doneToday, isTrue);
      expect(s.streak, 1);
      final day2 = DateTime(2026, 11, 15, 22);
      expect((await tracker.status(day2)).streak, 1);
      expect(await tracker.complete(day2), (streak: 2, first: true));
      final later = DateTime(2026, 11, 20);
      expect((await tracker.status(later)).streak, 0);
      expect(await tracker.complete(later), (streak: 1, first: true));
      await store.close();
    });
  });

  group('rewards (plan section 2.5)', () {
    final config = RemoteConfigValues.defaults;
    LevelReward reward({
      LevelKind kind = LevelKind.campaign,
      int livesLost = 0,
      ProgressEntry? previous,
      bool dailyDone = false,
      Set<StickerKey> owned = const {},
    }) => rewardFor(
      kind: kind,
      livesLost: livesLost,
      previous: previous,
      dailyAlreadyDone: dailyDone,
      config: config,
      ownedStickers: owned,
      random: math.Random(3),
    );

    ProgressEntry done(int stars) => ProgressEntry(
      levelId: 'L',
      stars: stars,
      attempts: 1,
      completedAt: DateTime(2026),
    );

    test(
      'first completion: 20 coins plus 10 per star above one, and a sticker',
      () {
        expect(reward().coins, 40);
        expect(reward().stars, 3);
        expect(reward(livesLost: 1).coins, 30);
        expect(reward(livesLost: 2).coins, 20);
        expect(reward().sticker, isNotNull);
        expect(reward().setBonus, 0);
      },
    );

    test('an attempt without a win still counts as first completion', () {
      const tried = ProgressEntry(levelId: 'L', stars: 0, attempts: 3);
      expect(reward(previous: tried).coins, 40);
      expect(reward(previous: tried).sticker, isNotNull);
    });

    test('the twelfth sticker pays the set bonus', () {
      final owned = {for (var i = 0; i < 11; i++) (set: 0, index: i)};
      final r = reward(owned: owned);
      expect(r.sticker, (set: 0, index: 11));
      expect(r.setBonus, 300);
      expect(r.total, 340);
    });

    test('replays pay a little and no sticker', () {
      final same = reward(previous: done(3));
      expect(same.coins, 5);
      expect(same.sticker, isNull);
      expect(reward(previous: done(1)).coins, 25, reason: 'two new stars');
      expect(reward(previous: done(3), livesLost: 2).coins, 5);
    });

    test(
      'daily pays once per day; events pay like levels without stickers',
      () {
        expect(reward(kind: LevelKind.daily).coins, 100);
        expect(reward(kind: LevelKind.daily, dailyDone: true).coins, 0);
        expect(reward(kind: LevelKind.daily).sticker, isNull);
        final ev = reward(kind: LevelKind.event);
        expect(ev.coins, 40);
        expect(ev.sticker, isNull);
      },
    );
  });

  group('level refs', () {
    test('round trip', () {
      for (final r in [
        const LevelRef.campaign('L012'),
        const LevelRef.daily(20261114),
        const LevelRef.event('ev1', 3),
      ]) {
        final back = LevelRef.tryParse(r.encode())!;
        expect(back.kind, r.kind);
        expect(back.id, r.id);
        expect(back.index, r.index);
        expect('$r', r.encode());
      }
    });

    test('rejects junk', () {
      for (final bad in [null, '', 'campaign:', 'daily:x', 'event:a', 'x:y']) {
        expect(LevelRef.tryParse(bad), isNull, reason: '$bad');
      }
    });
  });
}
