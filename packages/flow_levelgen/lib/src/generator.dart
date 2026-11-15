import 'dart:convert';

import 'package:flow_core/flow_core.dart';
import 'package:flow_solver/flow_solver.dart';

import 'templates.dart';

/// Options for a single generated level.
class GenRequest {
  const GenRequest({
    required this.id,
    required this.seed,
    required this.band,
    this.allowLocked = true,
    this.allowGates = true,
    this.require,
  });

  final String id;
  final int seed;
  final int band;
  final bool allowLocked;
  final bool allowGates;

  /// When set (`Mechanics.lockedBin` or `Mechanics.colourGate`) the level is
  /// guaranteed to feature that mechanic and no other.
  final String? require;
}

/// Stable fingerprint of a level's tree and belt, for duplicate rejection.
String levelHash(LevelDef level) =>
    '${jsonEncode(_shape(level.root))}|${level.belt.join(',')}';

Object _shape(Node n) => switch (n) {
  SwitchNode() => [_shape(n.left), _shape(n.right)],
  GateNode() => {'g': n.toColour.name, 'n': _shape(n.next)},
  BinNode() => '${n.colour.name}${n.unlockAfter ?? ''}',
};

class _Leaf {
  _Leaf(this.colour);

  final ItemColour colour;
  bool gated = false;
  bool locked = false;
  int count = 0;
  int? firstUse;
}

/// Builds one level from [req], or returns null when the candidate is
/// rejected (unsolvable, trivially easy, or structurally unusable).
///
/// The belt is built by simulating a player who makes at most
/// `reactionBudget` flips per tick, so a mistake-free solution exists by
/// construction; the solver then confirms it and measures the level.
LevelDef? generateLevel(GenRequest req) {
  final t = templateFor(req.band);
  final rng = SeededRng(req.seed);

  final wantGate =
      req.require == Mechanics.colourGate ||
      (req.require == null && req.allowGates && rng.nextBool(t.gateChance));
  final wantLock =
      req.require == Mechanics.lockedBin ||
      (req.require == null && req.allowLocked && rng.nextBool(t.lockChance));

  final nBins = rng.nextRange(t.minBins, t.maxBins);
  var nColours = rng.nextRange(t.minColours, t.maxColours);
  if (nColours > nBins) nColours = nBins;
  // Tutorial levels keep one bin per colour.
  final binColours = req.require != null ? nBins.clamp(2, 7) : nColours;

  final palette = [...ItemColour.values];
  if (req.band >= 3) rng.shuffle(palette);
  final leaves = <_Leaf>[
    for (var i = 0; i < nBins; i++)
      _Leaf(palette[i < binColours ? i : rng.nextInt(binColours)]),
  ];
  rng.shuffle(leaves);

  // A gate recolours whatever passes, so it can be fed colours that have no
  // bin of their own.
  final spare = palette.sublist(binColours.clamp(0, 7));
  final gateFeeds = <_Leaf, List<ItemColour>>{};
  if (wantGate) {
    final leaf = rng.pick(leaves)..gated = true;
    final others = [
      for (final c in palette.take(binColours))
        if (c != leaf.colour) c,
    ];
    gateFeeds[leaf] = [
      if (spare.isNotEmpty) spare.first else rng.pick(others),
      if (req.band >= 5 && rng.nextBool()) rng.pick(others),
    ];
  }
  _Leaf? lockedLeaf;
  if (wantLock) {
    final candidates = [
      for (final l in leaves)
        if (!l.gated) l,
    ];
    if (candidates.isEmpty) return null;
    lockedLeaf = rng.pick<_Leaf>(candidates)..locked = true;
  }

  // Random, roughly balanced binary tree over the leaves.
  var switchCount = 0;
  final placeholderBins = <_Leaf, String>{};
  Object build(int lo, int hi) {
    if (lo == hi) return leaves[lo];
    final n = hi - lo + 1;
    var left = n ~/ 2;
    if (n > 2 && rng.nextBool(0.4)) left = rng.nextRange(1, n - 1);
    final id = 's${++switchCount}';
    return (id, build(lo, lo + left - 1), build(lo + left, hi));
  }

  final shape = build(0, nBins - 1);
  final switchIds = [for (var i = 1; i <= switchCount; i++) 's$i'];
  for (var i = 0; i < leaves.length; i++) {
    placeholderBins[leaves[i]] = 'b${i + 1}';
  }

  _Leaf leafFor(int mask) {
    var node = shape;
    while (node is (String, Object, Object)) {
      final bit = switchIds.indexOf(node.$1);
      node = (mask >> bit) & 1 == 1 ? node.$3 : node.$2;
    }
    return node as _Leaf;
  }

  // All flip sets within the reaction budget.
  final actions = <int>[0];
  void addActions(int start, int mask, int left) {
    for (var i = start; i < switchCount; i++) {
      final m = mask | (1 << i);
      actions.add(m);
      if (left > 1) addActions(i + 1, m, left - 1);
    }
  }

  addActions(0, 0, t.reactionBudget);
  int bits(int v) {
    var c = 0;
    while (v != 0) {
      v &= v - 1;
      c++;
    }
    return c;
  }

  final beltLength = rng.nextRange(t.minBelt, t.maxBelt);
  final lockOpensAt =
      lockedLeaf == null ? 0 : rng.nextRange(2, (beltLength ~/ 2).clamp(2, 12));
  final initialMask = rng.nextInt(1 << switchCount);
  var mask = initialMask;
  _Leaf? last;
  final belt = <Item>[];

  for (var i = 0; i < beltLength; i++) {
    final byLeaf = <_Leaf, List<int>>{};
    for (final a in actions) {
      final leaf = leafFor(mask ^ a);
      if (leaf.locked && i < lockOpensAt) continue;
      (byLeaf[leaf] ??= []).add(a);
    }
    if (byLeaf.isEmpty) return null;
    // Favour a change of bin (more so in higher bands), bins that have had
    // fewer items so far, and targets that need fewer flips, so belts come
    // out as short runs rather than constant switching.
    final changeBias = 1.1 + 0.2 * t.band;
    final options = byLeaf.keys.toList();
    final weights = <double>[];
    for (final l in options) {
      var fewest = 99;
      for (final a in byLeaf[l]!) {
        final n = bits(a);
        if (n < fewest) fewest = n;
      }
      weights.add(
        (identical(l, last) ? 1.0 : changeBias) *
            (1 + 2 / (1 + l.count)) *
            (fewest <= 1 ? 1.0 : 0.45) *
            (l.locked ? 1.6 : 1.0) *
            (l.gated ? 1.4 : 1.0),
      );
    }
    var roll = rng.nextDouble() * weights.fold<double>(0, (a, b) => a + b);
    var target = options.last;
    for (var j = 0; j < options.length; j++) {
      roll -= weights[j];
      if (roll < 0) {
        target = options[j];
        break;
      }
    }
    final ways = byLeaf[target]!..sort((a, b) => bits(a).compareTo(bits(b)));
    final action = rng.nextBool(0.75) ? ways.first : rng.pick(ways);
    mask ^= action;

    final feeds = gateFeeds[target];
    final colour =
        feeds != null && rng.nextBool(0.85) ? rng.pick(feeds) : target.colour;
    belt.add(Item(colour));
    target
      ..count += 1
      ..firstUse ??= i;
    last = target;
  }

  if (leaves.any((l) => l.count == 0)) return null;
  if (wantGate && !belt.any((i) => gateFeeds.values.first.contains(i.colour))) {
    return null;
  }
  int? unlockAfter;
  if (lockedLeaf != null) {
    // Every earlier item was delivered correctly in the constructed run.
    unlockAfter = lockedLeaf.firstUse! - (rng.nextBool(0.4) ? 1 : 0);
    if (unlockAfter < 2) return null;
  }

  var gateCount = 0;
  Node materialise(Object node) {
    if (node is (String, Object, Object)) {
      return SwitchNode(
        node.$1,
        left: materialise(node.$2),
        right: materialise(node.$3),
      );
    }
    final leaf = node as _Leaf;
    final bin = BinNode(
      placeholderBins[leaf]!,
      colour: leaf.colour,
      capacity: leaf.count,
      unlockAfter: leaf.locked ? unlockAfter : null,
    );
    return leaf.gated
        ? GateNode('g${++gateCount}', toColour: leaf.colour, next: bin)
        : bin;
  }

  final level = LevelDef(
    id: req.id,
    seed: req.seed,
    root: materialise(shape),
    belt: belt,
    tickMs: t.tickMs,
    initialSwitches: {
      for (var i = 0; i < switchCount; i++)
        switchIds[i]:
            (initialMask >> i) & 1 == 1 ? SwitchDir.right : SwitchDir.left,
    },
    meta: LevelMeta(band: t.band, reactionBudget: t.reactionBudget),
  );

  final result = solve(level, reactionBudget: t.reactionBudget);
  if (!result.perfect || result.minFlips <= 1) return null;
  return level.copyWith(
    meta: level.meta.copyWith(
      difficulty: difficultyScore(
        level,
        result,
        reactionBudget: t.reactionBudget,
      ),
      parFlips: result.minFlips,
      mechanics: mechanicsOf(level),
    ),
  );
}

/// Generates up to [candidates] levels for one slot and returns them sorted
/// from easiest to hardest. Seeds are derived from [seed] so the result is
/// reproducible.
List<LevelDef> generateCandidates(
  GenRequest base, {
  int candidates = 6,
  Set<String>? seen,
}) {
  final out = <LevelDef>[];
  var attempt = 0;
  while (out.length < candidates && attempt < candidates * 40) {
    final seed = (base.seed * 31 + attempt * 7919 + 17) & 0x7FFFFFFF;
    attempt++;
    final level = generateLevel(
      GenRequest(
        id: base.id,
        seed: seed,
        band: base.band,
        allowLocked: base.allowLocked,
        allowGates: base.allowGates,
        require: base.require,
      ),
    );
    if (level == null) continue;
    if (seen != null && seen.contains(levelHash(level))) continue;
    out.add(level);
  }
  out.sort((a, b) => a.meta.difficulty.compareTo(b.meta.difficulty));
  return out;
}

/// `generate --band --count --seed`: [count] distinct levels for one band,
/// easiest first. Over-generates and keeps the strongest candidates.
List<LevelDef> generateBatch({
  required int band,
  required int count,
  required int seed,
  String idPrefix = 'G',
  Set<String>? seen,
}) {
  final hashes = seen ?? <String>{};
  final pool = <LevelDef>[];
  var attempt = 0;
  final wanted = count * 3;
  while (pool.length < wanted && attempt < wanted * 40) {
    final level = generateLevel(
      GenRequest(
        id: 'tmp',
        seed: (seed * 131 + attempt * 104729 + 7) & 0x7FFFFFFF,
        band: band,
      ),
    );
    attempt++;
    if (level == null || !hashes.add(levelHash(level))) continue;
    pool.add(level);
  }
  pool.sort((a, b) => b.meta.difficulty.compareTo(a.meta.difficulty));
  // Drop the most extreme tenth, keep the next `count`.
  final skip = pool.length > count ? (pool.length ~/ 10) : 0;
  final kept =
      pool.skip(skip).take(count).toList()
        ..sort((a, b) => a.meta.difficulty.compareTo(b.meta.difficulty));
  return [
    for (var i = 0; i < kept.length; i++)
      kept[i].copyWith(id: '$idPrefix${(i + 1).toString().padLeft(3, '0')}'),
  ];
}

/// The daily challenge for [date]: the same level for everyone, generated on
/// device from `seed = yyyymmdd` (plan §2.4).
LevelDef generateDaily(DateTime date, {int difficultyOffset = 0}) {
  final seed = dailySeed(date);
  final band = (3 + SeededRng(seed).nextInt(4) + difficultyOffset).clamp(
    minBand,
    maxBand,
  );
  final id = 'D$seed';
  final picks = generateCandidates(
    GenRequest(id: id, seed: seed, band: band),
    candidates: 3,
  );
  if (picks.isEmpty) {
    throw StateError('Could not generate a daily level for $seed');
  }
  return picks[picks.length ~/ 2];
}

/// Levels of a weekly event pack: [count] levels of rising difficulty.
List<LevelDef> generateEvent({
  required String eventId,
  required int seed,
  int band = 4,
  int count = 7,
}) {
  final seen = <String>{};
  final out = <LevelDef>[];
  for (var i = 0; i < count; i++) {
    final b = (band + (i * 2) ~/ count).clamp(minBand, maxBand);
    final picks = generateCandidates(
      GenRequest(id: '$eventId-${i + 1}', seed: seed * 100 + i, band: b),
      candidates: 3,
      seen: seen,
    );
    if (picks.isEmpty) {
      throw StateError('Could not generate event level ${i + 1}');
    }
    final level = picks[picks.length ~/ 2];
    seen.add(levelHash(level));
    out.add(level);
  }
  return out;
}
