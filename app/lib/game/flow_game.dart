import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../ui/palette.dart';
import '../ui/theme.dart';
import 'board_layout.dart';
import 'session_controller.dart';

/// The Flame scene for one level. It only draws and animates: every rule
/// lives in `flow_core`, and timing lives in [LevelSessionController].
class FlowGame extends FlameGame {
  FlowGame({
    required this.controller,
    required this.audio,
    required this.haptics,
    required this.itemsLeftText,
    this.showHints = false,
  });

  final LevelSessionController controller;
  final AudioService audio;
  final HapticsService haptics;
  final String Function(int remaining) itemsLeftText;

  /// Pulse the switch a new player should tap (tutorial levels).
  final bool showHints;

  late BoardLayout layout;

  /// The layout once the board has been sized, for widgets drawn over it.
  BoardLayout? get layoutOrNull => _builtFor == null ? null : layout;
  StreamSubscription<SessionEvent>? _sub;
  final Map<String, BinComponent> _bins = {};
  final Map<String, SwitchComponent> _switches = {};
  Size? _builtFor;

  LevelDef get level => controller.level;
  GameState get state => controller.state;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    _sub = controller.events.listen(_onEvent);
    _build();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _build();
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }

  void _build() {
    final s = Size(size.x, size.y);
    if (s.isEmpty || s == _builtFor) return;
    _builtFor = s;
    removeAll(children.toList());
    _bins.clear();
    _switches.clear();
    layout = BoardLayout(level, s);
    add(TrackComponent());
    for (final bin in level.bins) {
      add(_bins[bin.id] = BinComponent(bin));
    }
    for (final sw in level.switches) {
      add(_switches[sw.id] = SwitchComponent(sw));
    }
    add(BeltComponent());
  }

  @override
  void update(double dt) {
    controller.update(dt);
    super.update(dt);
  }

  /// Correct deliveries still in the air towards [binId].
  int inFlightTo(String binId) =>
      children
          .whereType<ItemComponent>()
          .where(
            (i) => i.delivery.binId == binId && i.delivery.outcome.isCorrect,
          )
          .length;

  void _onEvent(SessionEvent event) {
    switch (event) {
      case DeliveredEvent(:final delivery, :final tickMs):
        add(ItemComponent(delivery, (tickMs * 0.7).clamp(220, 520) / 1000));
      case FlippedEvent(:final switchId):
        audio.play(Sfx.tap);
        haptics.fire(Haptic.light);
        _switches[switchId]?.bump();
      case UndoneEvent():
        removeAll(children.whereType<ItemComponent>().toList());
      case PhaseEvent():
        break;
    }
  }

  void onArrived(Delivery d) {
    final bin = _bins[d.binId];
    if (bin == null) return;
    if (d.outcome.isCorrect) {
      audio.play(Sfx.correct);
      haptics.fire(Haptic.success);
      bin.celebrate();
      _burst(layout.binRect(d.binId).center, colourOf(d.arrivedColour), 10);
    } else {
      audio.play(Sfx.wrong);
      haptics.fire(Haptic.error);
      bin.reject();
      _burst(layout.nodes[d.binId]!, AppColors.bad, 14);
    }
  }

  /// Confetti over the whole board (called when the level is won).
  void confetti() {
    final rng = math.Random();
    for (var i = 0; i < 3; i++) {
      _burst(
        Offset(size.x * (0.2 + 0.3 * i), size.y * 0.35),
        itemColours.values.elementAt(rng.nextInt(7)),
        22,
        speed: 260,
        life: 1.2,
      );
    }
  }

  void _burst(
    Offset at,
    Color colour,
    int count, {
    double speed = 150,
    double life = 0.55,
  }) {
    final rng = math.Random();
    add(
      ParticleSystemComponent(
        position: Vector2(at.dx, at.dy),
        priority: 20,
        particle: Particle.generate(
          count: count,
          lifespan: life,
          generator: (i) {
            final a = rng.nextDouble() * math.pi * 2;
            final v = speed * (0.4 + rng.nextDouble() * 0.6);
            final r = 2.0 + rng.nextDouble() * 3;
            final paint = Paint();
            return AcceleratedParticle(
              acceleration: Vector2(0, 420),
              speed: Vector2(math.cos(a) * v, math.sin(a) * v - 60),
              child: ComputedParticle(
                renderer: (canvas, p) {
                  paint.color = colour.withAlpha(
                    ((1 - p.progress) * 255).round(),
                  );
                  canvas.drawCircle(Offset.zero, r, paint);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pipes between nodes, the highlighted route the next item will take, and
/// colour gates.
class TrackComponent extends Component with HasGameReference<FlowGame> {
  TrackComponent() : super(priority: 0);

  final _pipe =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.track;
  final _active =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.trackActive;
  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(Canvas canvas) {
    final l = game.layout;
    final width = l.tokenRadius * 0.62;
    _pipe.strokeWidth = width;
    _active.strokeWidth = width * 0.5;

    // Chute from the belt to the root.
    canvas.drawLine(l.drop, l.nodes[game.level.root.id]!, _pipe);
    for (final (a, b) in l.edges) {
      canvas.drawLine(l.nodes[a]!, l.nodes[b]!, _pipe);
    }

    // The route the next item would take right now.
    final path = <Offset>[l.drop];
    Node node = game.level.root;
    while (true) {
      path.add(l.nodes[node.id]!);
      switch (node) {
        case SwitchNode():
          node = node.child(game.state.switches[node.id] ?? SwitchDir.left);
          continue;
        case GateNode():
          node = node.next;
          continue;
        case BinNode():
          break;
      }
      break;
    }
    final route = Path()..moveTo(path.first.dx, path.first.dy);
    for (final p in path.skip(1)) {
      route.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(route, _active..strokeJoin = StrokeJoin.round);

    for (final gate in game.level.gates) {
      _gate(canvas, l.nodes[gate.id]!, gate.toColour, l.tokenRadius);
    }
  }

  void _gate(Canvas canvas, Offset at, ItemColour colour, double r) {
    final c = colourOf(colour);
    final outer = r * 1.05;
    canvas.drawCircle(at, outer, Paint()..color = AppColors.bgBottom);
    // Spinning dashed ring says "this changes things".
    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.2
          ..strokeCap = StrokeCap.round
          ..color = c;
    const dashes = 8;
    for (var i = 0; i < dashes; i++) {
      final start = _time * 1.2 + i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: at, radius: outer),
        start,
        math.pi / dashes,
        false,
        ring,
      );
    }
    canvas.drawCircle(at, r * 0.68, Paint()..color = c);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.drawPath(shapeOf(colour, r * 0.36), Paint()..color = Colors.white);
    canvas.restore();
  }
}

/// A tappable junction. The arrow shows where items go next.
class SwitchComponent extends PositionComponent
    with TapCallbacks, HasGameReference<FlowGame> {
  SwitchComponent(this.node) : super(anchor: Anchor.center, priority: 5);

  final SwitchNode node;
  double _angle = 0;
  double _bump = 0;
  double _time = 0;
  bool _angleSet = false;

  void bump() => _bump = 1;

  @override
  void onMount() {
    super.onMount();
    final l = game.layout;
    final at = l.nodes[node.id]!;
    position = Vector2(at.dx, at.dy);
    size = Vector2.all(l.tapDiameter);
  }

  double get _targetAngle {
    final l = game.layout;
    final dir = game.state.switches[node.id] ?? SwitchDir.left;
    final to = l.nodes[node.child(dir).id]! - l.nodes[node.id]!;
    return math.atan2(to.dy, to.dx);
  }

  @override
  void update(double dt) {
    _time += dt;
    final target = _targetAngle;
    if (!_angleSet) {
      _angle = target;
      _angleSet = true;
    } else {
      _angle += (target - _angle) * math.min(1, dt * 22);
    }
    if (_bump > 0) _bump = math.max(0, _bump - dt * 5);
  }

  @override
  void onTapDown(TapDownEvent event) => game.controller.flip(node.id);

  @override
  void render(Canvas canvas) {
    final r = game.layout.switchRadius * (1 + 0.14 * _bump);
    final c = Offset(size.x / 2, size.y / 2);

    if (game.showHints &&
        hintSwitch(game.level, game.state) == node.id &&
        !game.controller.isOver) {
      final pulse = 0.5 + 0.5 * math.sin(_time * 6);
      canvas.drawCircle(
        c,
        r * (1.35 + 0.25 * pulse),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = AppColors.accent.withAlpha((120 + 135 * pulse).round()),
      );
    }

    canvas.drawCircle(
      c + const Offset(0, 3),
      r,
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.84, Paint()..color = AppColors.surfaceHigh);

    // Arrow pointing down the active branch.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_angle);
    final arrow =
        Path()
          ..moveTo(r * 0.62, 0)
          ..lineTo(-r * 0.05, -r * 0.42)
          ..lineTo(-r * 0.05, -r * 0.14)
          ..lineTo(-r * 0.5, -r * 0.14)
          ..lineTo(-r * 0.5, r * 0.14)
          ..lineTo(-r * 0.05, r * 0.14)
          ..lineTo(-r * 0.05, r * 0.42)
          ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.trackActive);
    canvas.restore();
  }
}

/// A destination bin with its colour, shape, fill counter and lock.
class BinComponent extends Component with HasGameReference<FlowGame> {
  BinComponent(this.node) : super(priority: 3);

  final BinNode node;
  double _pulse = 0;
  double _shake = 0;
  String _label = '';
  TextPainter? _text;

  void celebrate() => _pulse = 1;
  void reject() => _shake = 1;

  @override
  void update(double dt) {
    if (_pulse > 0) _pulse = math.max(0, _pulse - dt * 4);
    if (_shake > 0) _shake = math.max(0, _shake - dt * 3);
  }

  TextPainter _painter(String label, double fontSize) {
    if (_text == null || _label != label) {
      _label = label;
      _text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _text!;
  }

  @override
  void render(Canvas canvas) {
    final l = game.layout;
    final s = game.state;
    final base = colourOf(node.colour);
    final locked = isLocked(node, s);
    final fill = ((s.binFill[node.id] ?? 0) - game.inFlightTo(node.id)).clamp(
      0,
      node.capacity,
    );
    final full = fill >= node.capacity;

    var rect = l.binRect(node.id);
    if (_shake > 0) {
      rect = rect.translate(math.sin(_shake * 28) * 5 * _shake, 0);
    }
    if (_pulse > 0) rect = rect.inflate(3 * _pulse);
    final radius = Radius.circular(rect.width * 0.2);
    final rr = RRect.fromRectAndRadius(rect, radius);

    canvas.drawRRect(
      rr.shift(const Offset(0, 4)),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(rr, Paint()..color = darken(base, 0.55));

    // Fill level rises from the bottom.
    final ratio = fill / node.capacity;
    if (ratio > 0) {
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left,
          rect.bottom - rect.height * ratio,
          rect.right,
          rect.bottom,
        ),
        Paint()..color = base,
      );
      canvas.restore();
    }
    canvas.drawRRect(
      rr.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _shake > 0 ? AppColors.bad : base,
    );

    final glyphR = rect.width * 0.2;
    final glyphAt = Offset(rect.center.dx, rect.top + rect.height * 0.38);
    canvas.save();
    canvas.translate(glyphAt.dx, glyphAt.dy);
    canvas.drawPath(
      shapeOf(node.colour, glyphR),
      Paint()..color = Colors.white.withAlpha(locked ? 90 : 235),
    );
    canvas.restore();

    final label = full ? '✓' : '$fill/${node.capacity}';
    final tp = _painter(label, (rect.width * 0.22).clamp(11.0, 16.0));
    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, rect.bottom - tp.height - 5),
    );

    if (locked) _lock(canvas, rect, node.unlockAfter! - s.delivered);
  }

  void _lock(Canvas canvas, Rect rect, int remaining) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.2)),
      Paint()..color = const Color(0xB3141A3A),
    );
    final w = rect.width * 0.46;
    final body = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.center.dy + w * 0.12),
      width: w,
      height: w * 0.8,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(body.center.dx, body.top),
        width: w * 0.6,
        height: w * 0.72,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.14
        ..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.14)),
      Paint()..color = AppColors.accent,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$remaining',
        style: TextStyle(
          fontSize: w * 0.5,
          fontWeight: FontWeight.w900,
          color: AppColors.onAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(body.center.dx - tp.width / 2, body.center.dy - tp.height / 2),
    );
  }
}

/// The conveyor: upcoming items slide towards the drop point and one leaves
/// on every tick.
class BeltComponent extends Component with HasGameReference<FlowGame> {
  BeltComponent() : super(priority: 8);

  int _labelFor = -1;
  TextPainter? _label;

  @override
  void render(Canvas canvas) {
    final l = game.layout;
    final c = game.controller;
    final s = game.state;
    final r = l.tokenRadius;
    final progress = c.tickProgress;

    // Belt surface from the drop point to the right edge.
    final belt = RRect.fromLTRBAndCorners(
      l.drop.dx - r - 8,
      l.beltY - r - 6,
      game.size.x + 20,
      l.beltY + r + 6,
      topLeft: Radius.circular(r + 6),
      bottomLeft: Radius.circular(r + 6),
    );
    canvas.drawRRect(belt, Paint()..color = AppColors.track);
    canvas.save();
    canvas.clipRRect(belt);
    final stripe =
        Paint()
          ..color = const Color(0x22FFFFFF)
          ..strokeWidth = 3;
    final shift = progress * l.slot;
    for (var x = l.drop.dx - shift; x < game.size.x + l.slot; x += l.slot / 2) {
      canvas.drawLine(
        Offset(x, l.beltY - r - 6),
        Offset(x - 8, l.beltY + r + 6),
        stripe,
      );
    }
    canvas.restore();

    // Tick timer ring at the drop point.
    final ring = Rect.fromCircle(center: l.drop, radius: r + 4);
    canvas.drawCircle(l.drop, r + 4, Paint()..color = AppColors.bgBottom);
    canvas.drawArc(
      ring,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color =
            s.slowTicksLeft > 0 ? const Color(0xFF7FD6FF) : AppColors.accent,
    );

    // Upcoming items, nearest first.
    if (s.status == GameStatus.playing) {
      for (var i = s.nextItemIndex; i < game.level.belt.length; i++) {
        final k = i - s.nextItemIndex;
        final x = l.drop.dx + (k + 1 - progress) * l.slot;
        if (x > game.size.x + r) break;
        final item = game.level.belt[i];
        paintToken(
          canvas,
          Offset(x, l.beltY),
          k == 0 ? r : r * 0.9,
          item.colour,
          mystery: item.modifier == ItemModifier.mystery,
        );
      }
    }

    // "N left" at the free left side of the belt.
    final remaining = game.level.belt.length - s.nextItemIndex;
    if (_label == null || _labelFor != remaining) {
      _labelFor = remaining;
      _label = TextPainter(
        text: TextSpan(
          text: game.itemsLeftText(remaining),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDim,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(40, l.drop.dx - r - 24));
    }
    _label!.paint(canvas, Offset(12, l.beltY - _label!.height / 2));
  }
}

/// An item travelling from the belt to its bin along the route that was
/// fixed at the moment it left.
class ItemComponent extends Component with HasGameReference<FlowGame> {
  ItemComponent(this.delivery, this.duration) : super(priority: 10);

  final Delivery delivery;
  final double duration;
  double _t = 0;
  late final List<Offset> _points;
  late final List<double> _lengths;
  late final double _total;
  late final int _gateSegment;

  @override
  void onMount() {
    super.onMount();
    final l = game.layout;
    _points = l.pathPoints(delivery.path);
    _lengths = [
      for (var i = 1; i < _points.length; i++)
        (_points[i] - _points[i - 1]).distance,
    ];
    _total = _lengths.fold(0, (a, b) => a + b);
    // Index of the path point where a gate recolours the item (if any).
    final gates = {for (final g in game.level.gates) g.id};
    final at = delivery.path.indexWhere(gates.contains);
    _gateSegment = at < 0 ? 1 << 30 : at + 1;
  }

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) {
      game.onArrived(delivery);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final eased = Curves.easeIn.transform(_t.clamp(0.0, 1.0));
    var remaining = eased * _total;
    var segment = 0;
    while (segment < _lengths.length - 1 && remaining > _lengths[segment]) {
      remaining -= _lengths[segment];
      segment++;
    }
    final len = _lengths[segment];
    final at =
        Offset.lerp(
          _points[segment],
          _points[segment + 1],
          len == 0 ? 1 : (remaining / len).clamp(0.0, 1.0),
        )!;
    final recoloured = segment + 1 > _gateSegment;
    paintToken(
      canvas,
      at,
      game.layout.tokenRadius * 0.92,
      recoloured ? delivery.arrivedColour : delivery.item.colour,
    );
  }
}
