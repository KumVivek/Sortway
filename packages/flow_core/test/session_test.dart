import 'dart:convert';

import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('session records deliveries, flips and moves', () {
    final session = GameSession(threeBin(belt: [r, b, g]));
    expect(session.canUndo, isFalse);
    expect(session.tick()!.binId, 'b1');
    session.flip('s1');
    expect(session.tick()!.binId, 'b2');
    session.flip('s2');
    expect(session.tick()!.binId, 'b3');
    expect(session.isOver, isTrue);
    expect(session.state.status, GameStatus.won);
    expect(session.flips, 2);
    expect(session.log, hasLength(3));
    expect(session.moves.map((m) => m.tick), [1, 2]);
    expect(session.tick(), isNull);
    expect(session.canUndo, isFalse, reason: 'no undo after a win');
  });

  test('flips after the end are ignored', () {
    final session = GameSession(threeBin(belt: [r]))..tick();
    session.flip('s1');
    expect(session.flips, 0);
    expect(session.moves, isEmpty);
  });

  test('undo can be repeated back to the start', () {
    final session = GameSession(threeBin(belt: [r, r, b]));
    session
      ..tick()
      ..tick();
    expect(session.undo()!.itemIndex, 1);
    expect(session.undo()!.itemIndex, 0);
    expect(session.undo(), isNull);
    expect(session.state.nextItemIndex, 0);
    expect(session.state.binFill['b1'], 0);
  });

  test('boosters revive a lost session', () {
    final session = GameSession(threeBin(belt: [b, r, r], lives: 1))..tick();
    expect(session.state.status, GameStatus.lost);
    session.addLife();
    expect(session.state.status, GameStatus.playing);
    session.slow();
    expect(session.state.slowTicksLeft, 10);
    session
      ..tick()
      ..tick();
    expect(session.state.status, GameStatus.won);
    session.addLife();
    session.slow();
    expect(session.moves, hasLength(2));
  });

  test('survives a JSON round trip mid-level', () {
    final level = threeBin(belt: [r, b, g, r]);
    final session =
        GameSession(level)
          ..tick()
          ..flip('s1')
          ..tick()
          ..slow();
    final json =
        jsonDecode(jsonEncode(session.toJson())) as Map<String, Object?>;
    final restored = GameSession.fromJson(level, json);
    expect(restored.state.toJson(), session.state.toJson());
    expect(restored.flips, 1);
    expect(restored.log, hasLength(2));
    expect(restored.canUndo, isTrue);
    expect(restored.undo()!.binId, 'b2');
  });

  group('determinism', () {
    test('same level and same moves give the same result', () {
      final level = threeBin(belt: [r, b, g, r, b, g, r, r], redCap: 4);
      GameState run() {
        final s = GameSession(level);
        s.tick();
        s.flip('s1');
        s.tick();
        s.flip('s2');
        s.tick();
        s.flip('s1');
        s.tick();
        s.flip('s1');
        s.flip('s2');
        s.tick();
        s.flip('s2');
        s.tick();
        s.flip('s1');
        s.tick();
        s.tick();
        return s.state;
      }

      final a = run();
      final b2 = run();
      expect(a.toJson(), b2.toJson());
      expect(a.status, GameStatus.won);
      expect(a.livesLost, 0);
    });

    test('replay reproduces a recorded run, including boosters', () {
      final level = threeBin(belt: [b, b, r, g, b], lives: 2);
      final s = GameSession(level);
      s.tick(); // wrong
      s.tick(); // wrong -> lost
      expect(s.state.status, GameStatus.lost);
      s.undo();
      s.flip('s1');
      s.tick(); // blue ok
      s.addLife();
      s.flip('s1');
      s.tick(); // red ok
      s.slow();
      s.flip('s1');
      s.flip('s2');
      s.tick(); // green ok
      s.flip('s2');
      s.tick(); // blue ok
      expect(s.state.status, GameStatus.won);

      final again = replay(level, s.moves);
      expect(again.toJson(), s.state.toJson());
    });

    test('replay with no moves just runs the belt', () {
      final level = threeBin(belt: [r, r, b]);
      final s = replay(level, const []);
      expect(s.status, GameStatus.won);
      expect(s.livesLost, 1);
    });

    test('move JSON round trip', () {
      const m = Move(MoveKind.flip, 3, 's1');
      final back = Move.fromJson(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, Object?>,
      );
      expect(back.kind, MoveKind.flip);
      expect(back.tick, 3);
      expect(back.switchId, 's1');
      expect(const Move(MoveKind.undo, 1).toJson().containsKey('s'), isFalse);
    });
  });
}
