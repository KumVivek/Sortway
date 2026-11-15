import 'package:flow_core/flow_core.dart';
import 'package:flow_solver/flow_solver.dart';
import 'package:test/test.dart';

const r = Item(ItemColour.red);
const b = Item(ItemColour.blue);
const g = Item(ItemColour.green);
const y = Item(ItemColour.yellow);

BinNode bin(String id, ItemColour c, int cap, {int? unlock}) =>
    BinNode(id, colour: c, capacity: cap, unlockAfter: unlock);

LevelDef two(List<Item> belt, {int redCap = 9, int blueCap = 9}) => LevelDef(
  id: 'two',
  seed: 0,
  root: SwitchNode(
    's1',
    left: bin('b1', ItemColour.red, redCap),
    right: bin('b2', ItemColour.blue, blueCap),
  ),
  belt: belt,
);

LevelDef four(List<Item> belt) => LevelDef(
  id: 'four',
  seed: 0,
  root: SwitchNode(
    's1',
    left: SwitchNode(
      's2',
      left: bin('b1', ItemColour.red, 9),
      right: bin('b2', ItemColour.blue, 9),
    ),
    right: SwitchNode(
      's3',
      left: bin('b3', ItemColour.green, 9),
      right: bin('b4', ItemColour.yellow, 9),
    ),
  ),
  belt: belt,
);

void main() {
  test('empty belt is trivially solved', () {
    final res = solve(two([]));
    expect(res.solvable, isTrue);
    expect(res.perfect, isTrue);
    expect(res.minFlips, 0);
  });

  test('counts the minimum flips', () {
    final res = solve(two([r, r, b, b, r]));
    expect(res.perfect, isTrue);
    expect(res.minFlips, 2);
    expect(res.optimalPath, [
      <String>[],
      <String>[],
      ['s1'],
      <String>[],
      ['s1'],
    ]);
    expect(res.minTightestGap, 2);
    expect(res.peakFlips, 1);
    expect(res.trapCount, 0);
  });

  test('the optimal path wins under the real rules', () {
    final level = four([r, g, b, y, r, y, g, b, b, r]);
    final res = solve(level);
    expect(res.perfect, isTrue);
    final end = playSolution(level, res);
    expect(end.status, GameStatus.won);
    expect(end.livesLost, 0);
  });

  test('pre-setting an off-path switch saves the day with budget 1', () {
    // red(b1) then yellow(b4): needs s1 and s3 flipped, but only one flip
    // fits between the ticks, so s3 must be flipped before the first tick.
    final level = four([r, y]);
    final res = solve(level, reactionBudget: 1);
    expect(res.perfect, isTrue);
    expect(res.minFlips, 2);
    expect(res.optimalPath.first, ['s3']);
    expect(res.optimalPath.last, ['s1']);
    expect(playSolution(level, res).status, GameStatus.won);
  });

  test('reaction budget can make a level imperfect or unsolvable', () {
    // blue(b2) first needs s2; yellow next needs s1+s3: 2 flips, budget 1.
    final level = four([b, y]);
    expect(solve(level, reactionBudget: 2).perfect, isTrue);
    final tight = solve(level, reactionBudget: 1);
    expect(tight.perfect, isFalse);
    expect(tight.solvable, isTrue, reason: 'winnable by losing a life');

    final never = solve(four([b, y, b, y, b, y, b, y]), reactionBudget: 0);
    expect(never.solvable, isFalse);
    expect(never.optimalPath, isEmpty);
  });

  test('overflow forces a non-perfect result', () {
    final res = solve(two([r, r, r], redCap: 2));
    expect(res.solvable, isTrue);
    expect(res.perfect, isFalse);
  });

  test('locked bins are respected', () {
    LevelDef locked(List<Item> belt) => LevelDef(
      id: 'locked',
      seed: 0,
      root: SwitchNode(
        's1',
        left: bin('b1', ItemColour.red, 9),
        right: bin('b2', ItemColour.blue, 9, unlock: 2),
      ),
      belt: belt,
    );
    expect(solve(locked([r, r, b])).perfect, isTrue);
    expect(solve(locked([r, b, r])).perfect, isFalse);
  });

  test('gates open extra routes', () {
    final level = LevelDef(
      id: 'gate',
      seed: 0,
      root: SwitchNode(
        's1',
        left: bin('b1', ItemColour.red, 1),
        right: GateNode(
          'g1',
          toColour: ItemColour.blue,
          next: bin('b2', ItemColour.blue, 9),
        ),
      ),
      belt: [r, r, g],
    );
    final res = solve(level);
    expect(res.perfect, isTrue);
    expect(playSolution(level, res).binFill, {'b1': 1, 'b2': 2});
  });

  test('detects traps: a correct-looking delivery that dooms the level', () {
    // Two red bins. The near one (b1, cap 1) is also the only path position
    // from which blue is one flip away... the far red bin (b3) sits behind
    // s2. With budget 1, sending the first red to b1 leaves s2 unset for the
    // forced second red.
    final level = LevelDef(
      id: 'trap',
      seed: 0,
      root: SwitchNode(
        's1',
        left: bin('b1', ItemColour.red, 1),
        right: SwitchNode(
          's2',
          left: bin('b2', ItemColour.blue, 9),
          right: bin('b3', ItemColour.red, 1),
        ),
      ),
      belt: [r, r],
      initialSwitches: const {'s1': SwitchDir.right, 's2': SwitchDir.right},
    );
    // Optimal: red->b3 (0 flips), then flip s1, red->b1.
    // Trap: flip s1 first (red->b1 looks right), then b3 needs s1 only: fine.
    // So make it deadly by filling: second red must go to b3 after b1.
    final res = solve(level, reactionBudget: 1);
    expect(res.perfect, isTrue);
    expect(res.minFlips, 1);

    final deadly = LevelDef(
      id: 'trap2',
      seed: 0,
      root: level.root,
      belt: [r, b, r],
      initialSwitches: const {'s1': SwitchDir.left, 's2': SwitchDir.right},
    );
    // red->b1 (0 flips) looks right, but then blue needs s1+s2 (2 flips).
    // The only perfect line: pre-flip s1 so red->b3, flip s2 for blue, then
    // flip s1 for the last red into b1.
    final r2 = solve(deadly, reactionBudget: 1);
    expect(r2.perfect, isTrue);
    expect(r2.minFlips, 3);
    expect(r2.trapCount, greaterThanOrEqualTo(1));
    expect(playSolution(deadly, r2).livesLost, 0);
  });

  test('solves the largest v1 level shape well inside 200 ms', () {
    // 8 bins, 7 colours, 40 items.
    const colours = ItemColour.values;
    Node build(int lo, int hi, List<int> counter) {
      if (lo == hi) {
        return bin('b$lo', colours[lo % 7], 40);
      }
      final mid = (lo + hi) ~/ 2;
      final id = 's${counter[0]++}';
      return SwitchNode(
        id,
        left: build(lo, mid, counter),
        right: build(mid + 1, hi, counter),
      );
    }

    final rng = SeededRng(42);
    final level = LevelDef(
      id: 'big',
      seed: 42,
      root: build(0, 7, [1]),
      belt: [for (var i = 0; i < 40; i++) Item(colours[rng.nextInt(7)])],
    );
    solve(level, reactionBudget: 3); // warm up the JIT
    final sw = Stopwatch()..start();
    final res = solve(level, reactionBudget: 3);
    sw.stop();
    expect(res.perfect, isTrue);
    expect(playSolution(level, res).status, GameStatus.won);
    expect(sw.elapsedMilliseconds, lessThan(200));
  });

  test('rejects trees that are too large', () {
    Node chain(int n) =>
        n == 0
            ? bin('b0', ItemColour.red, 1)
            : SwitchNode(
              's$n',
              left: bin('b$n', ItemColour.red, 1),
              right: chain(n - 1),
            );
    final level = LevelDef(id: 'x', seed: 0, root: chain(11), belt: [r]);
    expect(() => solve(level), throwsArgumentError);
  });

  group('difficulty', () {
    test('mechanicsOf reports what the level uses', () {
      final level = LevelDef(
        id: 'm',
        seed: 0,
        root: SwitchNode(
          's1',
          left: bin('b1', ItemColour.red, 3, unlock: 1),
          right: GateNode(
            'g1',
            toColour: ItemColour.red,
            next: bin('b2', ItemColour.red, 3),
          ),
        ),
        belt: const [Item(ItemColour.blue, modifier: ItemModifier.mystery), r],
      );
      expect(mechanicsOf(level), [
        Mechanics.lockedBin,
        Mechanics.colourGate,
        Mechanics.mystery,
        Mechanics.sharedColour,
      ]);
      expect(mechanicsOf(two([r])), isEmpty);
    });

    test('harder levels score higher and scores stay in 0..1', () {
      final easy = two([r, r, r, b, b, b, r, r]);
      final hard = four([r, y, b, g, r, y, b, g, y, r, g, b, r, y, b, g]);
      final e = difficultyScore(easy, solve(easy));
      final h = difficultyScore(hard, solve(hard));
      expect(e, inInclusiveRange(0, 1));
      expect(h, inInclusiveRange(0, 1));
      expect(h, greaterThan(e));
      expect(difficultyScore(easy, SolveResult.unsolvable), 0);
    });

    test('grade fills in meta and rejects imperfect levels', () {
      final graded = grade(four([r, g, b, y, r, y]));
      expect(graded.meta.parFlips, greaterThan(0));
      expect(graded.meta.difficulty, greaterThan(0));
      expect(graded.meta.reactionBudget, 2);
      expect(() => grade(two([r, r, r], redCap: 2)), throwsStateError);
    });
  });
}
