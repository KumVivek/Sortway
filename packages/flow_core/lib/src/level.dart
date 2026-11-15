import 'item.dart';
import 'node.dart';

/// Mechanic identifiers used in `LevelMeta.mechanics`.
abstract final class Mechanics {
  static const lockedBin = 'locked_bin';
  static const colourGate = 'colour_gate';
  static const mystery = 'mystery';
  static const sharedColour = 'shared_colour';
}

class LevelMeta {
  const LevelMeta({
    this.difficulty = 0,
    this.parFlips = 0,
    this.mechanics = const [],
    this.band = 1,
    this.hard = false,
    this.reactionBudget = 2,
    this.tutorial,
  });

  factory LevelMeta.fromJson(Map<String, Object?> json) => LevelMeta(
    difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
    parFlips: (json['parFlips'] as num?)?.toInt() ?? 0,
    mechanics:
        (json['mechanics'] as List<Object?>?)?.cast<String>().toList(
          growable: false,
        ) ??
        const [],
    band: (json['band'] as num?)?.toInt() ?? 1,
    hard: json['hard'] as bool? ?? false,
    reactionBudget: (json['reactionBudget'] as num?)?.toInt() ?? 2,
    tutorial: json['tutorial'] as String?,
  );

  /// 0..1 solver-derived difficulty score.
  final double difficulty;

  /// Fewest switch flips of a no-mistake solution.
  final int parFlips;
  final List<String> mechanics;

  /// Difficulty band 1..8 the level was generated for.
  final int band;

  /// Marked "Hard" on the level map.
  final bool hard;

  /// Flips per tick the solver assumed the player can make.
  final int reactionBudget;

  /// Key of the tutorial shown with this level, if any.
  final String? tutorial;

  LevelMeta copyWith({
    double? difficulty,
    int? parFlips,
    List<String>? mechanics,
    int? band,
    bool? hard,
    int? reactionBudget,
    String? tutorial,
  }) => LevelMeta(
    difficulty: difficulty ?? this.difficulty,
    parFlips: parFlips ?? this.parFlips,
    mechanics: mechanics ?? this.mechanics,
    band: band ?? this.band,
    hard: hard ?? this.hard,
    reactionBudget: reactionBudget ?? this.reactionBudget,
    tutorial: tutorial ?? this.tutorial,
  );

  Map<String, Object?> toJson() => {
    'difficulty': double.parse(difficulty.toStringAsFixed(3)),
    'parFlips': parFlips,
    'mechanics': mechanics,
    'band': band,
    if (hard) 'hard': true,
    'reactionBudget': reactionBudget,
    if (tutorial != null) 'tutorial': tutorial,
  };
}

class LevelDef {
  LevelDef({
    required this.id,
    required this.seed,
    required this.root,
    required List<Item> belt,
    this.tickMs = 600,
    this.lives = 3,
    Map<String, SwitchDir> initialSwitches = const {},
    this.meta = const LevelMeta(),
  }) : belt = List.unmodifiable(belt),
       switches = List.unmodifiable(walkTree(root).whereType<SwitchNode>()),
       bins = List.unmodifiable(walkTree(root).whereType<BinNode>()),
       gates = List.unmodifiable(walkTree(root).whereType<GateNode>()),
       initialSwitches = Map.unmodifiable({
         for (final s in walkTree(root).whereType<SwitchNode>())
           s.id: initialSwitches[s.id] ?? SwitchDir.left,
       }) {
    _validate(initialSwitches);
  }

  factory LevelDef.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final tree = json['tree'];
    final belt = json['belt'];
    if (id is! String) throw const FormatException('Level is missing "id"');
    if (tree is! Map<String, Object?>) {
      throw FormatException('Level "$id" is missing "tree"');
    }
    if (belt is! List<Object?>) {
      throw FormatException('Level "$id" is missing "belt"');
    }
    final initial = json['initialSwitches'] as Map<String, Object?>? ?? const {};
    final meta = json['meta'] as Map<String, Object?>?;
    return LevelDef(
      id: id,
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      root: Node.fromJson(tree),
      belt: [for (final i in belt) Item.fromJson(i)],
      tickMs: (json['tickMs'] as num?)?.toInt() ?? 600,
      lives: (json['lives'] as num?)?.toInt() ?? 3,
      initialSwitches: {
        for (final e in initial.entries)
          e.key: SwitchDir.parse(e.value! as String),
      },
      meta: meta == null ? const LevelMeta() : LevelMeta.fromJson(meta),
    );
  }

  final String id;
  final int seed;

  /// Tree entry point; the belt feeds the root.
  final Node root;

  /// Items in the order they leave the belt, one per tick.
  final List<Item> belt;
  final int tickMs;
  final int lives;

  /// Complete map: every switch has an entry.
  final Map<String, SwitchDir> initialSwitches;
  final LevelMeta meta;

  /// Switches, bins and gates in depth-first, left-to-right order.
  final List<SwitchNode> switches;
  final List<BinNode> bins;
  final List<GateNode> gates;

  LevelDef copyWith({String? id, int? tickMs, LevelMeta? meta}) => LevelDef(
    id: id ?? this.id,
    seed: seed,
    root: root,
    belt: belt,
    tickMs: tickMs ?? this.tickMs,
    lives: lives,
    initialSwitches: initialSwitches,
    meta: meta ?? this.meta,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'seed': seed,
    'tickMs': tickMs,
    'lives': lives,
    'tree': root.toJson(),
    'initialSwitches': {
      for (final e in initialSwitches.entries) e.key: e.value.name,
    },
    'belt': [for (final i in belt) i.toJson()],
    'meta': meta.toJson(),
  };

  void _validate(Map<String, SwitchDir> given) {
    final ids = <String>{};
    for (final n in walkTree(root)) {
      if (!ids.add(n.id)) {
        throw FormatException('Level "$id": duplicate node id "${n.id}"');
      }
    }
    for (final key in given.keys) {
      if (!initialSwitches.containsKey(key)) {
        throw FormatException(
          'Level "$id": initialSwitches names unknown switch "$key"',
        );
      }
    }
    for (final b in bins) {
      if (b.capacity < 1) {
        throw FormatException('Level "$id": bin "${b.id}" has no capacity');
      }
    }
    if (lives < 1) throw FormatException('Level "$id": lives must be >= 1');
    if (tickMs < 1) throw FormatException('Level "$id": tickMs must be >= 1');
  }
}

/// A versioned bundle of levels (see plan §6).
class LevelPack {
  LevelPack({
    required this.packId,
    required this.version,
    required List<LevelDef> levels,
  }) : levels = List.unmodifiable(levels);

  factory LevelPack.fromJson(Map<String, Object?> json) {
    final packId = json['packId'];
    final levels = json['levels'];
    if (packId is! String) {
      throw const FormatException('Pack is missing "packId"');
    }
    if (levels is! List<Object?>) {
      throw FormatException('Pack "$packId" is missing "levels"');
    }
    return LevelPack(
      packId: packId,
      version: (json['version'] as num?)?.toInt() ?? 1,
      levels: [
        for (final l in levels) LevelDef.fromJson(l! as Map<String, Object?>),
      ],
    );
  }

  final String packId;
  final int version;
  final List<LevelDef> levels;

  Map<String, Object?> toJson() => {
    'packId': packId,
    'version': version,
    'levels': [for (final l in levels) l.toJson()],
  };
}
