import 'package:flow_core/flow_core.dart';

/// Result of [solve].
class SolveResult {
  const SolveResult({
    required this.solvable,
    required this.perfect,
    required this.minFlips,
    required this.minTightestGap,
    required this.trapCount,
    required this.peakFlips,
    required this.optimalPath,
    required this.statesExplored,
  });

  /// The level can be won (losing lives is allowed).
  final bool solvable;

  /// The level can be won without losing a life.
  final bool perfect;

  /// Fewest flips of the best solution found (perfect when one exists).
  final int minFlips;

  /// Smallest number of ticks between two ticks that need a flip on the
  /// optimal path. Equals the belt length when fewer than two ticks need one.
  final int minTightestGap;

  /// Ticks on the optimal path where a delivery that looks right (correct
  /// bin) leaves the level unwinnable without losing a life.
  final int trapCount;

  /// Most flips needed before a single tick on the optimal path.
  final int peakFlips;

  /// For each tick, the switch ids to flip before it.
  final List<List<String>> optimalPath;
  final int statesExplored;

  static const unsolvable = SolveResult(
    solvable: false,
    perfect: false,
    minFlips: 0,
    minTightestGap: 0,
    trapCount: 0,
    peakFlips: 0,
    optimalPath: [],
    statesExplored: 0,
  );
}

/// Finds the cheapest way to clear [level] when the player can flip at most
/// [reactionBudget] switches between two ticks (and before the first one).
///
/// The belt releases exactly one item per tick, so the search is a layered
/// dynamic program: layer `i` holds every reachable
/// `(switches, binFill, livesLost)` just before item `i` leaves.
SolveResult solve(LevelDef level, {int reactionBudget = 2}) {
  if (level.belt.isEmpty) {
    return const SolveResult(
      solvable: true,
      perfect: true,
      minFlips: 0,
      minTightestGap: 0,
      trapCount: 0,
      peakFlips: 0,
      optimalPath: [],
      statesExplored: 1,
    );
  }
  final model = _Model(level, reactionBudget);
  final perfect = model.run(maxLivesLost: 0);
  if (perfect != null) return perfect;
  final any = model.run(maxLivesLost: level.lives - 1);
  return any ?? SolveResult.unsolvable;
}

class _Entry {
  _Entry(this.cost, this.parent, this.action);

  int cost;
  int parent;

  /// XOR mask of the switches flipped to get here.
  int action;

  /// 0 = not yet known, 1 = can still reach the end, 2 = dead end.
  int alive = 0;
}

/// States are packed into one int: switch mask (10 bits), lives lost
/// (2 bits), then 6 bits of fill per bin.
class _Model {
  _Model(this.level, this.budget)
    : switchIds = [for (final s in level.switches) s.id],
      nBins = level.bins.length {
    if (switchIds.length > _maskBits) {
      throw ArgumentError('Solver supports at most $_maskBits switches');
    }
    if (nBins > 8) throw ArgumentError('Solver supports at most 8 bins');
    if (level.lives > 4) throw ArgumentError('Solver supports at most 4 lives');
    if (level.belt.length > 63) {
      throw ArgumentError('Solver supports at most 63 items');
    }
    final nMasks = 1 << switchIds.length;
    leafOf = List.filled(nMasks, 0);
    gateColour = List.filled(nMasks, -1);
    final binIndex = {for (var i = 0; i < nBins; i++) level.bins[i].id: i};
    final switchIndex = {
      for (var i = 0; i < switchIds.length; i++) switchIds[i]: i,
    };
    for (var mask = 0; mask < nMasks; mask++) {
      var node = level.root;
      var colour = -1;
      while (node is! BinNode) {
        switch (node) {
          case SwitchNode():
            final right = (mask >> switchIndex[node.id]!) & 1 == 1;
            node = right ? node.right : node.left;
          case GateNode():
            colour = node.toColour.index;
            node = node.next;
          case BinNode():
            break;
        }
      }
      leafOf[mask] = binIndex[node.id]!;
      gateColour[mask] = colour;
    }
    actions = _actions(switchIds.length, budget);
    actionBits = [for (final a in actions) _bits(a)];
    binColour = [for (final b in level.bins) b.colour.index];
    binCapacity = [for (final b in level.bins) b.capacity];
    binUnlock = [for (final b in level.bins) b.unlockAfter ?? 0];
    beltColour = [for (final i in level.belt) i.colour.index];
    initialMask = 0;
    for (var i = 0; i < switchIds.length; i++) {
      if (level.initialSwitches[switchIds[i]] == SwitchDir.right) {
        initialMask |= 1 << i;
      }
    }
  }

  final LevelDef level;
  final int budget;
  final List<String> switchIds;
  final int nBins;
  late final List<int> leafOf;
  late final List<int> gateColour;
  late final List<int> actions;
  late final List<int> actionBits;
  late final List<int> binColour;
  late final List<int> binCapacity;
  late final List<int> binUnlock;
  late final List<int> beltColour;
  late int initialMask;

  static const _maskBits = 10;
  static const _maskAll = (1 << _maskBits) - 1;
  static const _livesShift = _maskBits;
  static const _fillShift = _maskBits + 2;
  static const _fillBits = 6;

  /// Set by [_deliver]: whether the last delivery was a correct one.
  bool _correct = false;

  /// Every XOR mask with at most [budget] bits set, cheapest first.
  static List<int> _actions(int n, int budget) {
    final out = <int>[0];
    void add(int start, int mask, int left) {
      for (var i = start; i < n; i++) {
        final m = mask | (1 << i);
        out.add(m);
        if (left > 1) add(i + 1, m, left - 1);
      }
    }

    if (budget > 0) add(0, 0, budget);
    out.sort((a, b) => _bits(a).compareTo(_bits(b)));
    return out;
  }

  static int _bits(int v) {
    var c = 0;
    while (v != 0) {
      v &= v - 1;
      c++;
    }
    return c;
  }

  static int _lost(int key) => (key >> _livesShift) & 3;

  /// Returns the packed state after item [index] leaves with switches
  /// [mask], or -1 when that would exceed [maxLivesLost].
  int _deliver(int index, int key, int mask, int maxLivesLost) {
    final binIdx = leafOf[mask];
    final gc = gateColour[mask];
    final colour = gc >= 0 ? gc : beltColour[index];
    final livesLost = _lost(key);
    final shift = _fillShift + binIdx * _fillBits;
    final rest = key & ~_maskAll;
    if (colour == binColour[binIdx] &&
        index - livesLost >= binUnlock[binIdx] &&
        ((key >> shift) & 0x3F) < binCapacity[binIdx]) {
      _correct = true;
      return (rest | mask) + (1 << shift);
    }
    _correct = false;
    if (livesLost + 1 > maxLivesLost) return -1;
    return (rest | mask) + (1 << _livesShift);
  }

  /// Whether the end is reachable from state [key] of layer [i]. Memoised
  /// depth-first search over the layers built by [run].
  bool _alive(List<Map<int, _Entry>> layers, int i, int key, int maxLost) {
    final entry = layers[i][key]!;
    if (entry.alive != 0) return entry.alive == 1;
    if (i == layers.length - 1) {
      entry.alive = 1;
      return true;
    }
    final mask = key & _maskAll;
    for (final a in actions) {
      final r = _deliver(i, key, mask ^ a, maxLost);
      if (r >= 0 && _alive(layers, i + 1, r, maxLost)) {
        entry.alive = 1;
        return true;
      }
    }
    entry.alive = 2;
    return false;
  }

  SolveResult? run({required int maxLivesLost}) {
    final n = level.belt.length;
    final layers = List.generate(n + 1, (_) => <int, _Entry>{});
    layers[0][initialMask] = _Entry(0, -1, 0);
    var explored = 1;
    final nActions = actions.length;

    for (var i = 0; i < n; i++) {
      final next = layers[i + 1];
      layers[i].forEach((key, entry) {
        final mask = key & _maskAll;
        for (var ai = 0; ai < nActions; ai++) {
          final a = actions[ai];
          final r = _deliver(i, key, mask ^ a, maxLivesLost);
          if (r < 0) continue;
          final cost = entry.cost + actionBits[ai];
          final existing = next[r];
          if (existing == null) {
            next[r] = _Entry(cost, key, a);
            explored++;
          } else if (cost < existing.cost) {
            existing
              ..cost = cost
              ..parent = key
              ..action = a;
          }
        }
      });
      if (next.isEmpty) return null;
    }

    // Best final state: fewest lives lost, then fewest flips.
    var bestKey = -1;
    _Entry? best;
    layers[n].forEach((key, entry) {
      final lost = _lost(key);
      if (best == null ||
          lost < _lost(bestKey) ||
          (lost == _lost(bestKey) && entry.cost < best!.cost)) {
        bestKey = key;
        best = entry;
      }
    });
    if (best == null) return null;

    // Walk the optimal path back to the start.
    final pathKeys = List<int>.filled(n + 1, 0);
    final pathActions = List<int>.filled(n, 0);
    var key = bestKey;
    for (var i = n; i > 0; i--) {
      pathKeys[i] = key;
      final entry = layers[i][key]!;
      pathActions[i - 1] = entry.action;
      key = entry.parent;
    }
    pathKeys[0] = key;

    var traps = 0;
    var peak = 0;
    var tightest = n;
    int? lastFlipTick;
    for (var i = 0; i < n; i++) {
      final flips = _bits(pathActions[i]);
      if (flips > peak) peak = flips;
      if (flips > 0) {
        if (lastFlipTick != null && i - lastFlipTick < tightest) {
          tightest = i - lastFlipTick;
        }
        lastFlipTick = i;
      }
      final from = pathKeys[i];
      final mask = from & _maskAll;
      for (final alt in actions) {
        final r = _deliver(i, from, mask ^ alt, maxLivesLost);
        if (r >= 0 && _correct && !_alive(layers, i + 1, r, maxLivesLost)) {
          traps++;
          break;
        }
      }
    }

    return SolveResult(
      solvable: true,
      perfect: maxLivesLost == 0,
      minFlips: best!.cost,
      minTightestGap: tightest,
      trapCount: traps,
      peakFlips: peak,
      optimalPath: [
        for (final a in pathActions)
          [
            for (var b = 0; b < switchIds.length; b++)
              if ((a >> b) & 1 == 1) switchIds[b],
          ],
      ],
      statesExplored: explored,
    );
  }
}

/// Plays [result]'s optimal path through the real rules. Used to cross-check
/// the solver against `flow_core`.
GameState playSolution(LevelDef level, SolveResult result) {
  var s = GameState.initial(level);
  for (final flips in result.optimalPath) {
    for (final id in flips) {
      s = flip(s, id);
    }
    s = step(level, s);
  }
  return s;
}
