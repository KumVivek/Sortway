import 'package:flow_core/flow_core.dart';

import '../../services/game_store.dart';

class DailyStatus {
  const DailyStatus({required this.doneToday, required this.streak});

  final bool doneToday;

  /// Consecutive days completed, counting today if done. Zero after a
  /// missed day — the streak simply starts counting again; nothing else is
  /// taken away (plan §2.4).
  final int streak;
}

int _dayNumber(int yyyymmdd) {
  final d = DateTime.utc(
    yyyymmdd ~/ 10000,
    (yyyymmdd ~/ 100) % 100,
    yyyymmdd % 100,
  );
  return d.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// Streak after completing the daily on [today], given the previous
/// completion day [lastDay] (both `yyyymmdd`, 0 = never).
int nextStreak({
  required int lastDay,
  required int today,
  required int streak,
}) {
  if (lastDay == today) return streak < 1 ? 1 : streak;
  if (lastDay != 0 && _dayNumber(today) - _dayNumber(lastDay) == 1) {
    return streak + 1;
  }
  return 1;
}

/// Streak to display on [today] before playing.
int shownStreak({
  required int lastDay,
  required int today,
  required int streak,
}) {
  if (lastDay == 0) return 0;
  final gap = _dayNumber(today) - _dayNumber(lastDay);
  return gap <= 1 && gap >= 0 ? streak : 0;
}

class DailyTracker {
  DailyTracker(this._store);

  final GameStore _store;

  static const _lastKey = 'daily_last';
  static const _streakKey = 'daily_streak';

  Future<DailyStatus> status(DateTime now) async {
    final today = dailySeed(now);
    final last = await _store.readInt(_lastKey);
    final streak = await _store.readInt(_streakKey);
    return DailyStatus(
      doneToday: last == today,
      streak: shownStreak(lastDay: last, today: today, streak: streak),
    );
  }

  /// Records today's completion. Returns the new streak and whether this was
  /// the first completion today (only that one earns the reward).
  Future<({int streak, bool first})> complete(DateTime now) async {
    final today = dailySeed(now);
    final last = await _store.readInt(_lastKey);
    final streak = nextStreak(
      lastDay: last,
      today: today,
      streak: await _store.readInt(_streakKey),
    );
    await _store.write(_lastKey, '$today');
    await _store.write(_streakKey, '$streak');
    return (streak: streak, first: last != today);
  }
}
