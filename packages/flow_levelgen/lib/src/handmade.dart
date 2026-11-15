import 'package:flow_core/flow_core.dart';
import 'package:flow_solver/flow_solver.dart';

/// The 30 hand-designed tutorial levels (mechanics M0–M1, plan §7.3).
///
/// Each level is written as a tree string and a belt string:
///  * tree: a letter is a bin of that colour, `(xy)` is a switch with left
///    branch `x` and right branch `y`;
///  * belt: one letter per item, in the order they leave the belt.
///
/// Letters: r red, b blue, g green, y yellow, p purple, o orange, k pink.
/// Bin capacity is the number of items of its colour on the belt.
class _Spec {
  const _Spec(
    this.tree,
    this.belt,
    this.tickMs, {
    this.init = '',
    this.tutorial,
  });

  final String tree;
  final String belt;
  final int tickMs;

  /// One `L`/`R` per switch in depth-first order; missing = left.
  final String init;
  final String? tutorial;
}

const _specs = <_Spec>[
  // M0 — one switch, two colours.
  _Spec('(rb)', 'rrrbbb', 1800, tutorial: 'tap_switch'),
  _Spec('(rb)', 'rbbrrbrb', 1700, tutorial: 'look_ahead'),
  _Spec('(rb)', 'brbrrbbrbr', 1500),
  // M0 — two switches, three colours.
  _Spec('(r(bg))', 'rrbbggrr', 1700, tutorial: 'second_switch'),
  _Spec('(r(bg))', 'rbgrbbgrg', 1600),
  _Spec('((rb)g)', 'ggrrbbgrbg', 1600, init: 'R'),
  _Spec('((rb)g)', 'rgbgrrbgbrgb', 1500),
  // M1 — four bins.
  _Spec('((rb)(gy))', 'rrbbggyyrg', 1600),
  _Spec('((rb)(gy))', 'rbrbgygyrbgy', 1550),
  _Spec('((rb)(gy))', 'rgrgbybyrygb', 1500),
  _Spec('((ry)(bg))', 'yybrgryybgrbg', 1500, init: 'LR'),
  _Spec('(r((bg)y))', 'rbgyrbgyyrbg', 1500),
  _Spec('((rb)(gy))', 'rygbrygbbgyrrb', 1450),
  _Spec('(((rb)g)y)', 'yrbgyyrbggbry', 1450, init: 'R'),
  _Spec('((rb)(gy))', 'bygrbygryrgbybr', 1400, init: 'LRR'),
  // M1 — five colours, deeper tree.
  _Spec('((rb)(g(yp)))', 'rrbbggyyppry', 1500),
  _Spec('((rb)(g(yp)))', 'rbgypprbgygp', 1450),
  _Spec('((r(bp))(gy))', 'rpbgyrpbygpbr', 1400),
  _Spec('((rb)(g(yp)))', 'ppyygrrbbgpyrg', 1400, init: 'RLRR'),
  _Spec('((rp)((bg)y))', 'rpbgyyrpgbbyrpg', 1350),
  _Spec('((rb)(g(yp)))', 'gyprbgyprbbrgpyy', 1350, init: 'RLL'),
  // M1 — six colours.
  _Spec('((r(bp))(g(yo)))', 'rrbbppggyyoorb', 1450),
  _Spec('((r(bp))(g(yo)))', 'rbpgyorbpgyoor', 1400),
  _Spec('(((rb)p)((gy)o))', 'rrbpggyoorbpgy', 1350),
  _Spec('((r(bp))(g(yo)))', 'ooyygrrbpgyobprg', 1300, init: 'RLLRR'),
  _Spec('(((rb)(pg))(yo))', 'rbpgyoyorbpgoyrb', 1300),
  _Spec('((r(bp))(g(yo)))', 'rrgbbpyoogrypbgo', 1250),
  _Spec('(((rb)p)((gy)o))', 'yyoggrbbpoygrrbpog', 1200, init: 'RLLLR'),
  _Spec('(((rb)(pg))(yo))', 'rrbyopggoyrbbpgoyp', 1200),
  // Finale — all seven colours.
  _Spec('((r(bp))((gy)(ok)))', 'rbpgyokrbpgyokkoygpbr', 1150),
];

const _letters = <String, ItemColour>{
  'r': ItemColour.red,
  'b': ItemColour.blue,
  'g': ItemColour.green,
  'y': ItemColour.yellow,
  'p': ItemColour.purple,
  'o': ItemColour.orange,
  'k': ItemColour.pink,
};

/// Parses the compact tree/belt notation used above into a level.
LevelDef parseCompactLevel({
  required String id,
  required String tree,
  required String belt,
  int tickMs = 600,
  String init = '',
  LevelMeta meta = const LevelMeta(),
  int seed = 0,
}) {
  final items = [
    for (final ch in belt.split(''))
      Item(_letters[ch] ?? (throw FormatException('Bad belt letter "$ch"'))),
  ];
  final counts = <ItemColour, int>{};
  for (final i in items) {
    counts[i.colour] = (counts[i.colour] ?? 0) + 1;
  }
  var pos = 0;
  var switches = 0;
  var bins = 0;
  final initial = <String, SwitchDir>{};
  Node parse() {
    if (pos >= tree.length) throw FormatException('Unexpected end of "$tree"');
    final ch = tree[pos++];
    if (ch == '(') {
      final index = switches++;
      final id = 's${index + 1}';
      if (index < init.length && init[index] == 'R') {
        initial[id] = SwitchDir.right;
      }
      final left = parse();
      final right = parse();
      if (pos >= tree.length || tree[pos++] != ')') {
        throw FormatException('Missing ")" in "$tree"');
      }
      return SwitchNode(id, left: left, right: right);
    }
    final colour = _letters[ch];
    if (colour == null) throw FormatException('Bad tree letter "$ch"');
    return BinNode('b${++bins}', colour: colour, capacity: counts[colour] ?? 1);
  }

  final root = parse();
  if (pos != tree.length) throw FormatException('Trailing input in "$tree"');
  return LevelDef(
    id: id,
    seed: seed,
    root: root,
    belt: items,
    tickMs: tickMs,
    initialSwitches: initial,
    meta: meta,
  );
}

String levelId(int number) => 'L${number.toString().padLeft(3, '0')}';

/// Hand-made level [number] (1-based) before grading.
LevelDef handmadeSpecLevel(int number) {
  final spec = _specs[number - 1];
  return parseCompactLevel(
    id: levelId(number),
    seed: number,
    tree: spec.tree,
    belt: spec.belt,
    tickMs: spec.tickMs,
    init: spec.init,
    meta: LevelMeta(
      band: 1 + ((number - 1) * 3) ~/ _specs.length,
      hard: number % 10 == 0,
      tutorial: spec.tutorial,
    ),
  );
}

/// Builds and grades the hand-made levels L001–L030.
List<LevelDef> handmadeLevels() => [
  for (var n = 1; n <= _specs.length; n++) grade(handmadeSpecLevel(n)),
];
