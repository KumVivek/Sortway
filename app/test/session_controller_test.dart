import 'package:flow_core/flow_core.dart';
import 'package:flow_levelgen/flow_levelgen.dart';
import 'package:flow_sort/game/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

LevelDef level(String tree, String belt, {int tickMs = 1000}) =>
    parseCompactLevel(id: 'T', tree: tree, belt: belt, tickMs: tickMs);

void main() {
  test('counts down, then releases one item per tick', () {
    final c = LevelSessionController(level: level('(rb)', 'rrr'));
    final phases = <PlayPhase>[];
    final deliveries = <Delivery>[];
    c.events.listen((e) {
      if (e is PhaseEvent) phases.add(e.phase);
      if (e is DeliveredEvent) deliveries.add(e.delivery);
    });
    expect(c.phase, PlayPhase.countdown);
    for (var i = 0; i < 29; i++) {
      c.update(0.1);
    }
    expect(c.phase, PlayPhase.countdown);
    c.update(0.1);
    c.update(0.1);
    expect(c.phase, PlayPhase.playing);
    expect(deliveries, isEmpty);
    for (var i = 0; i < 10; i++) {
      c.update(0.1);
    }
    expect(deliveries, hasLength(1));
    expect(c.tickProgress, closeTo(0.0, 0.11));
    for (var i = 0; i < 20; i++) {
      c.update(0.1);
    }
    expect(c.phase, PlayPhase.won);
    expect(phases, [PlayPhase.playing, PlayPhase.won]);
    expect(c.isOver, isTrue);
    expect(c.playSeconds, closeTo(3.0, 0.15));
    c.dispose();
  });

  test('a long frame cannot fast-forward the belt', () {
    final c = LevelSessionController(
      level: level('(rb)', 'rrrr'),
      countdownSeconds: 0,
    );
    c.update(0.01);
    c.update(30);
    expect(c.state.nextItemIndex, 0);
    c.update(-1);
    c.dispose();
  });

  test('flips work in the countdown and while playing, not when paused', () {
    final c = LevelSessionController(level: level('(rb)', 'bb'));
    var flips = 0;
    c.events.listen((e) {
      if (e is FlippedEvent) flips++;
    });
    c.flip('s1');
    expect(c.state.switches['s1'], SwitchDir.right);
    c.pause();
    expect(c.phase, PlayPhase.paused);
    c.flip('s1');
    c.update(5);
    expect(c.state.switches['s1'], SwitchDir.right);
    expect(c.countdownLeft, 3);
    c.resume();
    expect(c.phase, PlayPhase.countdown);
    expect(flips, 1);
    c.resume();
    c.dispose();
  });

  test('tick scale and the slow booster stretch the tick', () {
    final c = LevelSessionController(
      level: level('(rb)', 'rrrrrrrrrrrrrr'),
      tickScale: 1.5,
      countdownSeconds: 0,
    );
    c.update(0.01);
    expect(c.tickMs, 1500);
    expect(c.slow(), isTrue);
    expect(c.tickMs, 2400);
    expect(c.boostersUsed, {'slow': 1});
    c.dispose();
  });

  test(
    'losing, then undo or an extra life, restarts with a short countdown',
    () {
      LevelSessionController lost() {
        final l = LevelDef(
          id: 'one',
          seed: 0,
          lives: 1,
          tickMs: 500,
          root: level('(rb)', 'br').root,
          belt: const [Item(ItemColour.blue), Item(ItemColour.red)],
        );
        final c = LevelSessionController(level: l, countdownSeconds: 0);
        c.update(0.01);
        for (var i = 0; i < 6; i++) {
          c.update(0.1);
        }
        expect(c.phase, PlayPhase.lost);
        return c;
      }

      final a = lost();
      expect(a.slow(), isFalse);
      expect(a.undo(), isTrue);
      expect(a.phase, PlayPhase.countdown);
      expect(a.countdownLeft, LevelSessionController.reviveCountdown);
      expect(a.state.lives, 1);
      expect(a.state.nextItemIndex, 0);
      expect(a.undo(), isFalse, reason: 'nothing left to undo');
      a.dispose();

      final b = lost();
      expect(b.addLife(), isTrue);
      expect(b.phase, PlayPhase.countdown);
      expect(b.state.lives, 1);
      expect(b.state.nextItemIndex, 1);
      expect(b.boosterCount, 1);
      b.dispose();
    },
  );

  test('boosters do nothing after a win', () {
    final c = LevelSessionController(
      level: level('(rb)', 'r', tickMs: 100),
      countdownSeconds: 0,
    );
    c.update(0.01);
    c.update(0.1);
    c.update(0.1);
    expect(c.phase, PlayPhase.won);
    expect(c.undo(), isFalse);
    expect(c.addLife(), isFalse);
    expect(c.slow(), isFalse);
    c.pause();
    expect(c.phase, PlayPhase.won);
    c.dispose();
  });

  test('restores a saved session', () {
    final l = level('(rb)', 'rrb');
    final session = GameSession(l)..tick();
    final c = LevelSessionController(
      level: l,
      restore: GameSession.fromJson(l, session.toJson()),
    );
    expect(c.state.nextItemIndex, 1);
    expect(c.phase, PlayPhase.countdown);
    expect(c.canUndo, isTrue);
    c.dispose();
  });

  group('hintSwitch', () {
    test('points at the first wrong switch, or nothing when on course', () {
      final l = level('(r(bg))', 'gr');
      var s = GameState.initial(l);
      expect(hintSwitch(l, s), 's1');
      s = flip(s, 's1');
      expect(hintSwitch(l, s), 's2');
      s = flip(s, 's2');
      expect(hintSwitch(l, s), isNull);
      s = step(l, s);
      expect(hintSwitch(l, s), 's1');
      s = step(l, flip(s, 's1'));
      expect(hintSwitch(l, s), isNull, reason: 'level over');
    });

    test('skips locked and full bins and sees through gates', () {
      final gated = LevelDef(
        id: 'g',
        seed: 0,
        root: const SwitchNode(
          's1',
          left: BinNode('b1', colour: ItemColour.blue, capacity: 1),
          right: GateNode(
            'g1',
            toColour: ItemColour.red,
            next: BinNode('b2', colour: ItemColour.red, capacity: 2),
          ),
        ),
        belt: const [Item(ItemColour.green)],
      );
      expect(hintSwitch(gated, GameState.initial(gated)), 's1');

      final locked = LevelDef(
        id: 'l',
        seed: 0,
        root: const SwitchNode(
          's1',
          left: BinNode(
            'b1',
            colour: ItemColour.red,
            capacity: 1,
            unlockAfter: 1,
          ),
          right: BinNode('b2', colour: ItemColour.red, capacity: 1),
        ),
        belt: const [Item(ItemColour.red), Item(ItemColour.red)],
      );
      expect(hintSwitch(locked, GameState.initial(locked)), 's1');
    });
  });
}
