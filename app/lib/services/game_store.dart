import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

class ProgressEntry {
  const ProgressEntry({
    required this.levelId,
    required this.stars,
    required this.attempts,
    this.bestFlips,
    this.completedAt,
  });

  final String levelId;
  final int stars;
  final int attempts;
  final int? bestFlips;
  final DateTime? completedAt;

  bool get completed => completedAt != null;
}

typedef StickerKey = ({int set, int index});

/// What a finished level changed, written in one transaction.
class LevelEndResult {
  const LevelEndResult({
    required this.firstCompletion,
    required this.previousStars,
    required this.coins,
  });

  final bool firstCompletion;
  final int previousStars;

  /// Wallet balance after the reward.
  final int coins;
}

/// All persistent player data. Everything lives on device (plan §12.1).
class GameStore {
  GameStore(this._db);

  final AppDatabase _db;

  static const _coinsKey = 'coins';
  static const _snapshotKey = 'snapshot';

  Future<void> close() => _db.close();

  // ---- key/value -------------------------------------------------------

  Future<String?> read(String key) async {
    final row =
        await (_db.select(_db.keyValues)
          ..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) => _db
      .into(_db.keyValues)
      .insertOnConflictUpdate(
        KeyValuesCompanion.insert(key: key, value: value),
      );

  Future<void> remove(String key) =>
      (_db.delete(_db.keyValues)..where((t) => t.key.equals(key))).go();

  Future<int> readInt(String key, {int orElse = 0}) async =>
      int.tryParse(await read(key) ?? '') ?? orElse;

  // ---- wallet ----------------------------------------------------------

  /// Sets the starting balance once, on first launch.
  Future<void> ensureWallet(int startingCoins) async {
    await _db.transaction(() async {
      if (await read(_coinsKey) == null) {
        await write(_coinsKey, '$startingCoins');
      }
    });
  }

  Future<int> coins() => readInt(_coinsKey);

  Stream<int> watchCoins() => (_db.select(_db.keyValues)..where(
    (t) => t.key.equals(_coinsKey),
  )).watchSingleOrNull().map((r) => int.tryParse(r?.value ?? '') ?? 0);

  Future<int> addCoins(int amount) => _db.transaction(() async {
    final next = (await coins()) + amount;
    await write(_coinsKey, '${next < 0 ? 0 : next}');
    return next < 0 ? 0 : next;
  });

  /// Takes [amount] coins if the balance allows. Returns whether it did.
  Future<bool> spendCoins(int amount) => _db.transaction(() async {
    final have = await coins();
    if (amount < 0 || have < amount) return false;
    await write(_coinsKey, '${have - amount}');
    return true;
  });

  // ---- progress --------------------------------------------------------

  ProgressEntry _entry(LevelProgressData r) => ProgressEntry(
    levelId: r.levelId,
    stars: r.stars,
    attempts: r.attempts,
    bestFlips: r.bestFlips,
    completedAt: r.completedAt,
  );

  Stream<Map<String, ProgressEntry>> watchProgress() => _db
      .select(_db.levelProgress)
      .watch()
      .map((rows) => {for (final r in rows) r.levelId: _entry(r)});

  Future<Map<String, ProgressEntry>> progress() async => {
    for (final r in await _db.select(_db.levelProgress).get())
      r.levelId: _entry(r),
  };

  Future<void> recordAttempt(String levelId) => _db.transaction(() async {
    final row =
        await (_db.select(_db.levelProgress)
          ..where((t) => t.levelId.equals(levelId))).getSingleOrNull();
    await _db
        .into(_db.levelProgress)
        .insertOnConflictUpdate(
          LevelProgressCompanion.insert(
            levelId: levelId,
            stars: Value(row?.stars ?? 0),
            bestFlips: Value(row?.bestFlips),
            attempts: Value((row?.attempts ?? 0) + 1),
            completedAt: Value(row?.completedAt),
          ),
        );
  });

  /// Saves a finished level and its reward atomically: best stars, fewest
  /// flips, coins and (optionally) a sticker either all land or none do.
  Future<LevelEndResult> completeLevel({
    required String levelId,
    required int stars,
    required int flips,
    required int Function(bool firstCompletion, int previousStars) coinsFor,
    StickerKey? sticker,
    DateTime? now,
  }) => _db.transaction(() async {
    final at = now ?? DateTime.now();
    final row =
        await (_db.select(_db.levelProgress)
          ..where((t) => t.levelId.equals(levelId))).getSingleOrNull();
    final first = row?.completedAt == null;
    final previous = row?.stars ?? 0;
    final best = row?.bestFlips;
    await _db
        .into(_db.levelProgress)
        .insertOnConflictUpdate(
          LevelProgressCompanion.insert(
            levelId: levelId,
            stars: Value(stars > previous ? stars : previous),
            bestFlips: Value(best == null || flips < best ? flips : best),
            attempts: Value(row?.attempts ?? 1),
            completedAt: Value(row?.completedAt ?? at),
          ),
        );
    if (sticker != null) {
      await _db
          .into(_db.stickers)
          .insert(
            StickersCompanion.insert(
              setIndex: sticker.set,
              stickerIndex: sticker.index,
              earnedAt: at,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final balance = await addCoins(coinsFor(first, previous));
    await remove(_snapshotKey);
    return LevelEndResult(
      firstCompletion: first,
      previousStars: previous,
      coins: balance,
    );
  });

  // ---- stickers --------------------------------------------------------

  Stream<Set<StickerKey>> watchStickers() => _db
      .select(_db.stickers)
      .watch()
      .map(
        (rows) => {
          for (final r in rows) (set: r.setIndex, index: r.stickerIndex),
        },
      );

  Future<Set<StickerKey>> stickers() async => {
    for (final r in await _db.select(_db.stickers).get())
      (set: r.setIndex, index: r.stickerIndex),
  };

  // ---- in-progress level (survives an app kill) ------------------------

  Future<void> saveSnapshot(Map<String, Object?> snapshot) =>
      write(_snapshotKey, jsonEncode(snapshot));

  Future<Map<String, Object?>?> loadSnapshot() async {
    final raw = await read(_snapshotKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, Object?>;
    } on Object {
      await remove(_snapshotKey);
      return null;
    }
  }

  Future<void> clearSnapshot() => remove(_snapshotKey);
}
