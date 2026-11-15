import 'dart:math' as math;

import 'package:flow_core/flow_core.dart';

import '../../services/game_store.dart';
import '../../services/remote_config_service.dart';
import '../levels/level_ref.dart';
import '../meta/stickers.dart';

/// Everything a won level pays out, decided in one place.
class LevelReward {
  const LevelReward({
    required this.stars,
    required this.coins,
    this.sticker,
    this.setBonus = 0,
  });

  final int stars;

  /// Coins for the level itself (what "double coins" doubles).
  final int coins;

  /// Sticker pulled for a first-time campaign completion.
  final StickerKey? sticker;

  /// Extra coins when [sticker] completes its set.
  final int setBonus;

  int get total => coins + setBonus;
}

/// Coins per extra star above the first (plan §2.5).
const int coinsPerExtraStar = 10;

/// Works out the reward for winning a level.
///
///  * Campaign / event, first completion: `coins_level_complete` plus 10 per
///    star above one. Campaign also pulls one sticker.
///  * Replays: a quarter of the base, plus 10 per newly earned star, so
///    replaying is worth a little but cannot be farmed.
///  * Daily: `coins_daily` for the first completion of the day, then nothing.
LevelReward rewardFor({
  required LevelKind kind,
  required int livesLost,
  required ProgressEntry? previous,
  required bool dailyAlreadyDone,
  required RemoteConfigValues config,
  required Set<StickerKey> ownedStickers,
  required math.Random random,
}) {
  final stars = starsFor(livesLost);
  final first = previous == null || !previous.completed;
  if (kind == LevelKind.daily) {
    return LevelReward(
      stars: stars,
      coins: dailyAlreadyDone ? 0 : config.coinsDaily,
    );
  }
  if (!first) {
    final gained = stars - previous.stars;
    return LevelReward(
      stars: stars,
      coins:
          config.coinsLevelComplete ~/ 4 +
          coinsPerExtraStar * (gained > 0 ? gained : 0),
    );
  }
  final coins = coinsForLevel(
    stars: stars,
    base: config.coinsLevelComplete,
    perExtraStar: coinsPerExtraStar,
  );
  if (kind != LevelKind.campaign)
    return LevelReward(stars: stars, coins: coins);
  final sticker = pullSticker(ownedStickers, random);
  return LevelReward(
    stars: stars,
    coins: coins,
    sticker: sticker,
    setBonus:
        completesSet(ownedStickers, sticker) ? config.coinsSetComplete : 0,
  );
}
