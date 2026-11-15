import 'dart:async';

import 'package:flow_core/flow_core.dart';
import 'package:flutter/foundation.dart';

enum PlayPhase { countdown, playing, paused, won, lost }

sealed class SessionEvent {
  const SessionEvent();
}

class DeliveredEvent extends SessionEvent {
  const DeliveredEvent(this.delivery, this.tickMs);

  final Delivery delivery;

  /// Length of the tick that released the item (drives animation speed).
  final int tickMs;
}

class FlippedEvent extends SessionEvent {
  const FlippedEvent(this.switchId);
  final String switchId;
}

class UndoneEvent extends SessionEvent {
  const UndoneEvent(this.delivery);
  final Delivery delivery;
}

class PhaseEvent extends SessionEvent {
  const PhaseEvent(this.phase);
  final PlayPhase phase;
}

/// Drives one level in real time on top of the pure `flow_core` rules:
/// countdown, tick timing, pause, boosters. Has no Flutter or Flame
/// dependencies beyond [ChangeNotifier], so it is unit-testable by calling
/// [update] with elapsed seconds.
class LevelSessionController extends ChangeNotifier {
  LevelSessionController({
    required this.level,
    this.tickScale = 1,
    GameSession? restore,
    double countdownSeconds = 3,
  }) : session = restore ?? GameSession(level),
       _countdownLeft = countdownSeconds {
    if (session.state.status == GameStatus.won) _phase = PlayPhase.won;
    if (session.state.status == GameStatus.lost) _phase = PlayPhase.lost;
  }

  static const double reviveCountdown = 1.5;

  final LevelDef level;
  final double tickScale;
  final GameSession session;
  final Map<String, int> boostersUsed = {};

  final _events = StreamController<SessionEvent>.broadcast(sync: true);
  PlayPhase _phase = PlayPhase.countdown;
  PlayPhase _beforePause = PlayPhase.countdown;
  double _countdownLeft;
  double _accMs = 0;
  double _playSeconds = 0;

  Stream<SessionEvent> get events => _events.stream;
  PlayPhase get phase => _phase;
  GameState get state => session.state;
  double get countdownLeft => _countdownLeft;

  /// Seconds of actual play (countdown and pauses excluded).
  double get playSeconds => _playSeconds;
  int get boosterCount => boostersUsed.values.fold(0, (a, b) => a + b);
  bool get isOver => _phase == PlayPhase.won || _phase == PlayPhase.lost;
  bool get canUndo => session.canUndo;

  int get tickMs => effectiveTickMs(level, state, scale: tickScale);

  /// 0..1 progress towards the next tick.
  double get tickProgress =>
      _phase == PlayPhase.playing || _phase == PlayPhase.paused
          ? (_accMs / tickMs).clamp(0.0, 1.0)
          : 0;

  void _setPhase(PlayPhase next) {
    if (_phase == next) return;
    _phase = next;
    _events.add(PhaseEvent(next));
  }

  /// Advances real time by [dt] seconds.
  void update(double dt) {
    if (dt <= 0) return;
    // A long frame (app resumed, debugger pause) must not fast-forward.
    final step = dt > 0.1 ? 0.1 : dt;
    switch (_phase) {
      case PlayPhase.countdown:
        _countdownLeft -= step;
        if (_countdownLeft <= 0) {
          _countdownLeft = 0;
          _accMs = 0;
          _setPhase(PlayPhase.playing);
        }
        notifyListeners();
      case PlayPhase.playing:
        _playSeconds += step;
        _accMs += step * 1000;
        while (_phase == PlayPhase.playing && _accMs >= tickMs) {
          final length = tickMs;
          _accMs -= length;
          final delivery = session.tick();
          if (delivery != null) _events.add(DeliveredEvent(delivery, length));
          switch (state.status) {
            case GameStatus.won:
              _setPhase(PlayPhase.won);
            case GameStatus.lost:
              _setPhase(PlayPhase.lost);
            case GameStatus.playing:
              break;
          }
        }
        notifyListeners();
      case PlayPhase.paused || PlayPhase.won || PlayPhase.lost:
        break;
    }
  }

  /// Flips a switch. Allowed during the countdown and while playing.
  void flip(String switchId) {
    if (_phase != PlayPhase.countdown && _phase != PlayPhase.playing) return;
    final before = session.flips;
    session.flip(switchId);
    if (session.flips == before) return;
    _events.add(FlippedEvent(switchId));
    notifyListeners();
  }

  void pause() {
    if (_phase != PlayPhase.countdown && _phase != PlayPhase.playing) return;
    _beforePause = _phase;
    _setPhase(PlayPhase.paused);
    notifyListeners();
  }

  void resume() {
    if (_phase != PlayPhase.paused) return;
    _setPhase(_beforePause);
    notifyListeners();
  }

  void _count(String booster) =>
      boostersUsed[booster] = (boostersUsed[booster] ?? 0) + 1;

  void _restartAfterRevive() {
    _accMs = 0;
    _countdownLeft = reviveCountdown;
    if (_phase == PlayPhase.paused) {
      _beforePause = PlayPhase.countdown;
    } else {
      _setPhase(PlayPhase.countdown);
    }
  }

  /// Booster: rewinds the last delivery. Returns false if there is none.
  bool undo() {
    if (_phase == PlayPhase.won) return false;
    final undone = session.undo();
    if (undone == null) return false;
    _count('undo');
    _events.add(UndoneEvent(undone));
    _restartAfterRevive();
    notifyListeners();
    return true;
  }

  /// Booster: +1 life. Revives a lost level.
  bool addLife() {
    if (_phase == PlayPhase.won) return false;
    final wasLost = state.status == GameStatus.lost;
    session.addLife();
    _count('life');
    if (wasLost) {
      if (state.status == GameStatus.won) {
        _setPhase(PlayPhase.won);
      } else {
        _restartAfterRevive();
      }
    }
    notifyListeners();
    return true;
  }

  /// Booster: slower belt for the next ten ticks.
  bool slow() {
    if (state.status != GameStatus.playing || isOver) return false;
    session.slow();
    _count('slow');
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}

/// The switch a new player should tap next: the first switch on the way to
/// the nearest bin that would accept the next item whose direction is wrong.
/// Null when the item is already on course (or nothing can accept it).
String? hintSwitch(LevelDef level, GameState state) {
  if (state.status != GameStatus.playing ||
      state.nextItemIndex >= level.belt.length) {
    return null;
  }
  final item = level.belt[state.nextItemIndex];
  String? best;
  var bestFlips = 1 << 30;

  void visit(Node node, ItemColour colour, String? firstWrong, int flips) {
    switch (node) {
      case SwitchNode():
        final current = state.switches[node.id] ?? SwitchDir.left;
        for (final dir in SwitchDir.values) {
          final wrong = dir != current;
          visit(
            node.child(dir),
            colour,
            firstWrong ?? (wrong ? node.id : null),
            flips + (wrong ? 1 : 0),
          );
        }
      case GateNode():
        visit(node.next, node.toColour, firstWrong, flips);
      case BinNode():
        final accepts =
            node.colour == colour &&
            !isLocked(node, state) &&
            (state.binFill[node.id] ?? 0) < node.capacity;
        if (accepts && flips < bestFlips) {
          bestFlips = flips;
          best = firstWrong;
        }
    }
  }

  visit(level.root, item.colour, null, 0);
  return best;
}
