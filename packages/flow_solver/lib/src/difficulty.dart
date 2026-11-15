import 'package:flow_core/flow_core.dart';

import 'solver.dart';

/// Mechanics a level actually uses, derived from its tree and belt.
List<String> mechanicsOf(LevelDef level) {
  final colours = <ItemColour>{};
  var shared = false;
  for (final b in level.bins) {
    if (!colours.add(b.colour)) shared = true;
  }
  return [
    if (level.bins.any((b) => b.unlockAfter != null)) Mechanics.lockedBin,
    if (level.gates.isNotEmpty) Mechanics.colourGate,
    if (level.belt.any((i) => i.modifier == ItemModifier.mystery))
      Mechanics.mystery,
    if (shared) Mechanics.sharedColour,
  ];
}

/// Weighted 0..1 difficulty score (plan §7.2 step 4).
double difficultyScore(
  LevelDef level,
  SolveResult r, {
  int reactionBudget = 2,
}) {
  if (!r.solvable || level.belt.isEmpty) return 0;
  final items = level.belt.length;
  final flipsPerItem = (r.minFlips / items / 1.2).clamp(0.0, 1.0);
  final gap = r.minTightestGap <= 0 ? 0.0 : (1 / r.minTightestGap);
  final traps = (r.trapCount / 6).clamp(0.0, 1.0);
  final colours =
      ({for (final i in level.belt) i.colour}.length - 2).clamp(0, 5) / 5;
  final mechanics = (mechanicsOf(level).length / 3).clamp(0.0, 1.0);
  final length = ((items - 8) / 32).clamp(0.0, 1.0);
  final pressure = reactionBudget <= 1 ? 1.0 : 0.0;
  final speed = ((1500 - level.tickMs) / 900).clamp(0.0, 1.0);
  final score =
      0.24 * flipsPerItem +
      0.08 * gap +
      0.16 * traps +
      0.12 * colours +
      0.10 * mechanics +
      0.10 * length +
      0.08 * pressure +
      0.12 * speed;
  return score.clamp(0.0, 1.0);
}

/// Solves [level] and returns it with solver-derived metadata filled in.
/// Throws [StateError] when the level cannot be cleared without a mistake.
LevelDef grade(LevelDef level, {int? reactionBudget}) {
  final k = reactionBudget ?? level.meta.reactionBudget;
  final r = solve(level, reactionBudget: k);
  if (!r.perfect) {
    throw StateError('Level "${level.id}" has no mistake-free solution (k=$k)');
  }
  return level.copyWith(
    meta: level.meta.copyWith(
      difficulty: difficultyScore(level, r, reactionBudget: k),
      parFlips: r.minFlips,
      mechanics: mechanicsOf(level),
      reactionBudget: k,
    ),
  );
}
