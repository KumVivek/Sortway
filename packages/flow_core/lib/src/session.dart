import 'level.dart';
import 'rules.dart' as rules;
import 'state.dart';

/// A player input, recorded so a run can be replayed and verified.
enum MoveKind { flip, undo, addLife, slow }

class Move {
  const Move(this.kind, this.tick, [this.switchId]);

  factory Move.fromJson(Map<String, Object?> json) => Move(
    MoveKind.values.byName(json['k']! as String),
    json['t']! as int,
    json['s'] as String?,
  );

  final MoveKind kind;

  /// Value of `GameState.tick` when the move was made.
  final int tick;
  final String? switchId;

  Map<String, Object?> toJson() => {
    'k': kind.name,
    't': tick,
    if (switchId != null) 's': switchId,
  };
}

/// Mutable wrapper around the pure rules: holds the current state, the
/// delivery log (for undo) and the move list (for replay).
class GameSession {
  GameSession(this.level)
    : _state = GameState.initial(level),
      _log = [],
      _moves = [];

  GameSession.restore(
    this.level, {
    required GameState state,
    List<Delivery> log = const [],
    List<Move> moves = const [],
    this.flips = 0,
  }) : _state = state,
       _log = [...log],
       _moves = [...moves];

  factory GameSession.fromJson(LevelDef level, Map<String, Object?> json) =>
      GameSession.restore(
        level,
        state: GameState.fromJson(json['state']! as Map<String, Object?>),
        log: [
          for (final d in json['log']! as List<Object?>)
            Delivery.fromJson(d! as Map<String, Object?>),
        ],
        moves: [
          for (final m in json['moves']! as List<Object?>)
            Move.fromJson(m! as Map<String, Object?>),
        ],
        flips: json['flips'] as int? ?? 0,
      );

  final LevelDef level;
  GameState _state;
  final List<Delivery> _log;
  final List<Move> _moves;

  /// Switch flips made by the player.
  int flips = 0;

  GameState get state => _state;
  List<Delivery> get log => List.unmodifiable(_log);
  List<Move> get moves => List.unmodifiable(_moves);
  bool get canUndo => _log.isNotEmpty && _state.status != GameStatus.won;
  bool get isOver => _state.status != GameStatus.playing;

  void flip(String switchId) {
    final next = rules.flip(_state, switchId);
    if (identical(next, _state)) return;
    _state = next;
    flips++;
    _moves.add(Move(MoveKind.flip, _state.tick, switchId));
  }

  /// Advances one tick and returns the delivery it produced, if any.
  Delivery? tick() {
    final before = _state;
    _state = rules.step(level, _state);
    if (identical(before, _state) || _state.tick == before.tick) return null;
    final d = _state.lastDelivery!;
    _log.add(d);
    return d;
  }

  /// Rewinds the last delivery. Returns it, or null when there is none.
  Delivery? undo() {
    if (!canUndo) return null;
    final d = _log.removeLast();
    _moves.add(Move(MoveKind.undo, _state.tick));
    _state = rules.undoDelivery(level, _state, d);
    return d;
  }

  void addLife() {
    if (_state.status == GameStatus.won) return;
    _moves.add(Move(MoveKind.addLife, _state.tick));
    _state = rules.addLife(level, _state);
  }

  void slow() {
    if (_state.status != GameStatus.playing) return;
    _moves.add(Move(MoveKind.slow, _state.tick));
    _state = rules.applySlow(_state);
  }

  Map<String, Object?> toJson() => {
    'state': _state.toJson(),
    'log': [for (final d in _log) d.toJson()],
    'moves': [for (final m in _moves) m.toJson()],
    'flips': flips,
  };
}

/// Re-runs [moves] against [level] from the start. Every tick at which the
/// recorded run delivered an item is stepped in order, so the same level and
/// the same moves always give the same final state (used for determinism
/// tests and, later, server-side score validation).
GameState replay(LevelDef level, List<Move> moves) {
  final session = GameSession(level);
  var i = 0;
  // Each loop turn applies the moves recorded at the current tick, then
  // steps. An undo lowers the tick, so its follow-up moves sort naturally.
  var guard = 0;
  final limit = (level.belt.length + moves.length + 1) * 4;
  while (guard++ < limit) {
    while (i < moves.length && moves[i].tick == session.state.tick) {
      final m = moves[i++];
      switch (m.kind) {
        case MoveKind.flip:
          session.flip(m.switchId!);
        case MoveKind.undo:
          session.undo();
        case MoveKind.addLife:
          session.addLife();
        case MoveKind.slow:
          session.slow();
      }
    }
    if (session.state.status != GameStatus.playing) {
      if (i >= moves.length) break;
      // Remaining moves must be a revive (undo / extra life) on a lost level.
      if (moves[i].tick != session.state.tick) break;
      continue;
    }
    session.tick();
  }
  return session.state;
}
