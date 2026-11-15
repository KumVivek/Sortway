import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('initial state', () {
    test('fills in defaults for every switch and bin', () {
      final level = threeBin(belt: [r, b]);
      final s = GameState.initial(level);
      expect(s.switches, {'s1': SwitchDir.left, 's2': SwitchDir.left});
      expect(s.binFill, {'b1': 0, 'b2': 0, 'b3': 0});
      expect(s.lives, 3);
      expect(s.status, GameStatus.playing);
      expect(s.lastDelivery, isNull);
    });

    test('an empty belt is already won', () {
      final s = GameState.initial(threeBin(belt: []));
      expect(s.status, GameStatus.won);
      expect(step(threeBin(belt: []), s).status, GameStatus.won);
    });
  });

  group('routing', () {
    test('follows the switch directions at the instant of the tick', () {
      final level = threeBin(belt: [r, b, g]);
      var s = GameState.initial(level);
      s = step(level, s);
      expect(s.lastDelivery!.binId, 'b1');
      expect(s.lastDelivery!.path, ['s1', 'b1']);
      expect(s.lastDelivery!.outcome, DeliveryOutcome.correct);

      s = flip(s, 's1');
      s = step(level, s);
      expect(s.lastDelivery!.binId, 'b2');
      expect(s.lastDelivery!.path, ['s1', 's2', 'b2']);

      s = flip(s, 's2');
      s = step(level, s);
      expect(s.lastDelivery!.binId, 'b3');
      expect(s.binFill, {'b1': 1, 'b2': 1, 'b3': 1});
      expect(s.delivered, 3);
      expect(s.status, GameStatus.won);
      expect(s.lives, 3);
    });

    test('flip is instant, toggles, and rejects unknown switches', () {
      final level = threeBin(belt: [r]);
      final s = GameState.initial(level);
      final f = flip(s, 's2');
      expect(f.switches['s2'], SwitchDir.right);
      expect(f.tick, s.tick);
      expect(flip(f, 's2').switches['s2'], SwitchDir.left);
      expect(() => flip(s, 'nope'), throwsArgumentError);
    });

    test('flip does nothing once the level is over', () {
      final level = threeBin(belt: [r]);
      final won = step(level, GameState.initial(level));
      expect(won.status, GameStatus.won);
      expect(identical(flip(won, 's1'), won), isTrue);
      expect(identical(step(level, won), won), isTrue);
    });

    test('states are immutable', () {
      final s = GameState.initial(threeBin(belt: [r]));
      expect(() => s.switches['s1'] = SwitchDir.right, throwsUnsupportedError);
      expect(() => s.binFill['b1'] = 9, throwsUnsupportedError);
    });
  });

  group('lives', () {
    test('wrong bin costs a life and does not fill the bin', () {
      final level = threeBin(belt: [b, r]);
      var s = step(level, GameState.initial(level));
      expect(s.lastDelivery!.outcome, DeliveryOutcome.wrongBin);
      expect(s.lives, 2);
      expect(s.livesLost, 1);
      expect(s.binFill['b1'], 0);
      expect(s.delivered, 0);
      s = step(level, s);
      expect(s.status, GameStatus.won);
      expect(starsFor(s.livesLost), 2);
    });

    test('overflow costs a life', () {
      final level = threeBin(belt: [r, r, r], redCap: 2);
      var s = GameState.initial(level);
      s = step(level, step(level, s));
      expect(s.binFill['b1'], 2);
      s = step(level, s);
      expect(s.lastDelivery!.outcome, DeliveryOutcome.overflow);
      expect(s.binFill['b1'], 2);
      expect(s.lives, 2);
      expect(s.status, GameStatus.won);
    });

    test('zero lives loses the level, even on the last item', () {
      final level = threeBin(belt: [b, b, b]);
      var s = GameState.initial(level);
      s = step(level, step(level, step(level, s)));
      expect(s.lives, 0);
      expect(s.status, GameStatus.lost);
      expect(s.nextItemIndex, 3);
    });

    test('losing stops the belt', () {
      final level = threeBin(belt: [b, b, b, r, r], lives: 2);
      var s = GameState.initial(level);
      s = step(level, step(level, s));
      expect(s.status, GameStatus.lost);
      expect(s.nextItemIndex, 2);
      expect(identical(step(level, s), s), isTrue);
    });
  });

  group('locked bins', () {
    test('reject items until enough were delivered elsewhere', () {
      final level = threeBin(
        belt: [b, r, r, b],
        blueUnlockAfter: 2,
        initial: {'s1': SwitchDir.right},
      );
      var s = GameState.initial(level);
      expect(isLocked(level.bins[1], s), isTrue);
      s = step(level, s);
      expect(s.lastDelivery!.outcome, DeliveryOutcome.locked);
      expect(s.lives, 2);
      expect(s.binFill['b2'], 0);

      s = flip(s, 's1');
      s = step(level, step(level, s));
      expect(s.delivered, 2);
      expect(isLocked(level.bins[1], s), isFalse);

      s = flip(s, 's1');
      s = step(level, s);
      expect(s.lastDelivery!.outcome, DeliveryOutcome.correct);
      expect(s.binFill['b2'], 1);
      expect(s.status, GameStatus.won);
    });

    test('failed deliveries do not count towards unlocking', () {
      final level = threeBin(belt: [g, g, b], blueUnlockAfter: 1, lives: 5);
      var s = GameState.initial(level);
      s = step(level, step(level, s)); // two greens into the red bin
      expect(s.delivered, 0);
      expect(isLocked(level.bins[1], s), isTrue);
    });
  });

  group('gates', () {
    test('recolour items that pass through', () {
      final level = gated(belt: [g, b]);
      var s = flip(GameState.initial(level), 's1');
      s = step(level, s);
      final d = s.lastDelivery!;
      expect(d.item.colour, ItemColour.green);
      expect(d.arrivedColour, ItemColour.red);
      expect(d.path, ['s1', 'g1', 'b2']);
      expect(d.outcome, DeliveryOutcome.correct);

      // A blue item through the gate also arrives red.
      s = step(level, s);
      expect(s.lastDelivery!.outcome, DeliveryOutcome.correct);
      expect(s.binFill['b2'], 2);
    });

    test('an ungated wrong colour is still wrong', () {
      final level = gated(belt: [g]);
      final s = step(level, GameState.initial(level));
      expect(s.lastDelivery!.outcome, DeliveryOutcome.wrongBin);
    });
  });

  group('boosters', () {
    test('undo rewinds a correct delivery', () {
      final level = threeBin(belt: [r, r]);
      final before = GameState.initial(level);
      final after = step(level, before);
      final undone = undoDelivery(level, after, after.lastDelivery!);
      expect(undone.nextItemIndex, 0);
      expect(undone.binFill['b1'], 0);
      expect(undone.delivered, 0);
      expect(undone.tick, 0);
      expect(undone.lastDelivery, isNull);
    });

    test('undo restores a lost life and revives a lost level', () {
      final level = threeBin(belt: [b, r], lives: 1);
      final lost = step(level, GameState.initial(level));
      expect(lost.status, GameStatus.lost);
      final undone = undoDelivery(level, lost, lost.lastDelivery!);
      expect(undone.status, GameStatus.playing);
      expect(undone.lives, 1);
      expect(undone.livesLost, 0);
    });

    test('undo only accepts the most recent delivery', () {
      final level = threeBin(belt: [r, r, r]);
      final s1 = step(level, GameState.initial(level));
      final s2 = step(level, s1);
      expect(
        () => undoDelivery(level, s2, s1.lastDelivery!),
        throwsArgumentError,
      );
    });

    test('extra life revives, or wins if the belt is already empty', () {
      final mid = threeBin(belt: [b, r], lives: 1);
      final lostMid = step(mid, GameState.initial(mid));
      final revived = addLife(mid, lostMid);
      expect(revived.lives, 1);
      expect(revived.status, GameStatus.playing);
      expect(revived.livesLost, 1);

      final end = threeBin(belt: [b], lives: 1);
      final lostEnd = step(end, GameState.initial(end));
      expect(addLife(end, lostEnd).status, GameStatus.won);

      final won = step(threeBin(belt: [r]), GameState.initial(threeBin(belt: [r])));
      expect(identical(addLife(threeBin(belt: [r]), won), won), isTrue);
    });

    test('slow belt lasts ten ticks at 1.6x', () {
      final level = threeBin(belt: List.filled(12, r), redCap: 12);
      var s = applySlow(GameState.initial(level));
      expect(s.slowTicksLeft, 10);
      expect(effectiveTickMs(level, s), 960);
      expect(effectiveTickMs(level, s, scale: 0.5), 480);
      for (var i = 0; i < 10; i++) {
        s = step(level, s);
      }
      expect(s.slowTicksLeft, 0);
      expect(effectiveTickMs(level, s), 600);
      s = step(level, s);
      expect(s.slowTicksLeft, 0);
    });

    test('slow belt is ignored after the level ends', () {
      final level = threeBin(belt: [r]);
      final won = step(level, GameState.initial(level));
      expect(identical(applySlow(won), won), isTrue);
    });
  });

  group('scoring', () {
    test('stars', () {
      expect(starsFor(0), 3);
      expect(starsFor(1), 2);
      expect(starsFor(2), 1);
      expect(starsFor(5), 1);
    });

    test('coins', () {
      expect(coinsForLevel(stars: 1, base: 20), 20);
      expect(coinsForLevel(stars: 2, base: 20), 30);
      expect(coinsForLevel(stars: 3, base: 20), 40);
    });

    test('daily seed is yyyymmdd', () {
      expect(dailySeed(DateTime(2026, 11, 4)), 20261104);
    });
  });
}
