import 'item.dart';
import 'level.dart';
import 'node.dart';
import 'state.dart';

/// Slow-belt booster: tick length multiplier and duration (plan §2.3).
const double slowBeltFactor = 1.6;
const int slowBeltTicks = 10;

/// Where an item ends up for a given set of switch directions.
class RouteResult {
  const RouteResult(this.bin, this.colour, this.path);

  final BinNode bin;

  /// Item colour on arrival (after gates).
  final ItemColour colour;
  final List<String> path;
}

/// Routes [item] through the whole tree using [switches] as they are now.
RouteResult route(LevelDef level, Map<String, SwitchDir> switches, Item item) {
  var colour = item.colour;
  final path = <String>[];
  var node = level.root;
  while (true) {
    path.add(node.id);
    switch (node) {
      case SwitchNode():
        node = node.child(switches[node.id] ?? SwitchDir.left);
      case GateNode(:final toColour, :final next):
        colour = toColour;
        node = next;
      case BinNode():
        return RouteResult(node, colour, List.unmodifiable(path));
    }
  }
}

/// True while [bin] has not been unlocked in state [s].
bool isLocked(BinNode bin, GameState s) =>
    bin.unlockAfter != null && s.delivered < bin.unlockAfter!;

/// Flips one switch. No-op once the level is over.
GameState flip(GameState s, String switchId) {
  final current = s.switches[switchId];
  if (current == null) {
    throw ArgumentError.value(switchId, 'switchId', 'Unknown switch');
  }
  if (s.status != GameStatus.playing) return s;
  return s.copyWith(switches: {...s.switches, switchId: current.flipped});
}

/// Advances one tick: the next item leaves the belt and is routed to a bin
/// using the switch directions at this instant.
GameState step(LevelDef level, GameState s) {
  if (s.status != GameStatus.playing) return s;
  if (s.nextItemIndex >= level.belt.length) {
    return s.copyWith(status: GameStatus.won, clearLastDelivery: true);
  }
  final item = level.belt[s.nextItemIndex];
  final r = route(level, s.switches, item);
  final bin = r.bin;
  final fill = s.binFill[bin.id] ?? 0;

  final DeliveryOutcome outcome;
  if (r.colour != bin.colour) {
    outcome = DeliveryOutcome.wrongBin;
  } else if (isLocked(bin, s)) {
    outcome = DeliveryOutcome.locked;
  } else if (fill >= bin.capacity) {
    outcome = DeliveryOutcome.overflow;
  } else {
    outcome = DeliveryOutcome.correct;
  }

  final ok = outcome.isCorrect;
  final lives = ok ? s.lives : s.lives - 1;
  final next = s.nextItemIndex + 1;
  final status =
      lives <= 0
          ? GameStatus.lost
          : next >= level.belt.length
          ? GameStatus.won
          : GameStatus.playing;

  return s.copyWith(
    tick: s.tick + 1,
    lives: lives,
    livesLost: ok ? s.livesLost : s.livesLost + 1,
    binFill: ok ? {...s.binFill, bin.id: fill + 1} : s.binFill,
    nextItemIndex: next,
    delivered: ok ? s.delivered + 1 : s.delivered,
    status: status,
    slowTicksLeft: s.slowTicksLeft > 0 ? s.slowTicksLeft - 1 : 0,
    lastDelivery: Delivery(
      itemIndex: s.nextItemIndex,
      item: item,
      arrivedColour: r.colour,
      binId: bin.id,
      outcome: outcome,
      path: r.path,
    ),
  );
}

/// Booster: rewinds [d], which must be the most recent delivery of [s].
/// Puts the item back on the belt and restores the life if one was lost.
/// Switch directions are left as the player has them now.
GameState undoDelivery(LevelDef level, GameState s, Delivery d) {
  if (d.itemIndex != s.nextItemIndex - 1) {
    throw ArgumentError('Only the most recent delivery can be undone');
  }
  final ok = d.outcome.isCorrect;
  return s.copyWith(
    tick: s.tick - 1,
    lives: ok ? s.lives : s.lives + 1,
    livesLost: ok ? s.livesLost : s.livesLost - 1,
    binFill:
        ok ? {...s.binFill, d.binId: (s.binFill[d.binId] ?? 1) - 1} : s.binFill,
    nextItemIndex: d.itemIndex,
    delivered: ok ? s.delivered - 1 : s.delivered,
    status: GameStatus.playing,
    clearLastDelivery: true,
  );
}

/// Booster: +1 life now. Revives a lost level.
GameState addLife(LevelDef level, GameState s) {
  if (s.status == GameStatus.won) return s;
  return s.copyWith(
    lives: s.lives + 1,
    status:
        s.nextItemIndex >= level.belt.length
            ? GameStatus.won
            : GameStatus.playing,
  );
}

/// Booster: slows the belt for the next [ticks] ticks.
GameState applySlow(GameState s, {int ticks = slowBeltTicks}) {
  if (s.status != GameStatus.playing) return s;
  return s.copyWith(slowTicksLeft: s.slowTicksLeft + ticks);
}

/// Length of the upcoming tick in milliseconds.
int effectiveTickMs(LevelDef level, GameState s, {double scale = 1}) {
  final base = level.tickMs * scale;
  return (s.slowTicksLeft > 0 ? base * slowBeltFactor : base).round();
}
