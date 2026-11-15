import 'dart:math' as math;
import 'dart:ui';

import 'package:flow_core/flow_core.dart';

/// Colour-blind-safe item palette. Every colour also has its own shape, so
/// colour is never the only cue.
const Map<ItemColour, Color> itemColours = {
  ItemColour.red: Color(0xFFE5484D),
  ItemColour.blue: Color(0xFF3B8BEB),
  ItemColour.green: Color(0xFF1FAF76),
  ItemColour.yellow: Color(0xFFF7C948),
  ItemColour.purple: Color(0xFF9B6BDF),
  ItemColour.orange: Color(0xFFF2843A),
  ItemColour.pink: Color(0xFFF178B6),
};

Color colourOf(ItemColour c) => itemColours[c]!;

Color darken(Color c, [double amount = 0.25]) =>
    Color.lerp(c, const Color(0xFF000000), amount)!;

Color lighten(Color c, [double amount = 0.25]) =>
    Color.lerp(c, const Color(0xFFFFFFFF), amount)!;

/// Shape glyph for [colour], centred on the origin with "radius" [r].
/// red circle · blue square · green triangle · yellow star · purple diamond ·
/// orange hexagon · pink heart.
Path shapeOf(ItemColour colour, double r) {
  final p = Path();
  switch (colour) {
    case ItemColour.red:
      p.addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.9));
    case ItemColour.blue:
      p.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.8),
          Radius.circular(r * 0.15),
        ),
      );
    case ItemColour.green:
      _polygon(p, 3, r * 1.05, -math.pi / 2, dy: r * 0.12);
    case ItemColour.yellow:
      for (var i = 0; i < 10; i++) {
        final rad = i.isEven ? r * 1.05 : r * 0.48;
        final a = -math.pi / 2 + i * math.pi / 5;
        final pt = Offset(math.cos(a) * rad, math.sin(a) * rad);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      p.close();
    case ItemColour.purple:
      _polygon(p, 4, r * 1.05, -math.pi / 2);
    case ItemColour.orange:
      _polygon(p, 6, r * 0.98, 0);
    case ItemColour.pink:
      final s = r * 0.95;
      p
        ..moveTo(0, s * 0.95)
        ..cubicTo(-s * 1.5, -s * 0.1, -s * 0.75, -s * 1.15, 0, -s * 0.4)
        ..cubicTo(s * 0.75, -s * 1.15, s * 1.5, -s * 0.1, 0, s * 0.95)
        ..close();
  }
  return p;
}

void _polygon(Path p, int sides, double r, double start, {double dy = 0}) {
  for (var i = 0; i < sides; i++) {
    final a = start + i * 2 * math.pi / sides;
    final pt = Offset(math.cos(a) * r, math.sin(a) * r + dy);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
}

/// Draws a belt item: a coloured disc with its white shape glyph, or a grey
/// "?" disc when [mystery] is set.
void paintToken(
  Canvas canvas,
  Offset centre,
  double radius,
  ItemColour colour, {
  bool mystery = false,
  double opacity = 1,
}) {
  final base = mystery ? const Color(0xFF7B86B3) : colourOf(colour);
  final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
  canvas.drawCircle(
    centre + Offset(0, radius * 0.12),
    radius,
    Paint()..color = darken(base, 0.45).withAlpha(alpha),
  );
  canvas.drawCircle(centre, radius, Paint()..color = base.withAlpha(alpha));
  canvas.drawCircle(
    centre,
    radius * 0.8,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..color = lighten(base, 0.35).withAlpha(alpha),
  );
  final glyph = Paint()..color = const Color(0xFFFFFFFF).withAlpha(alpha);
  canvas.save();
  canvas.translate(centre.dx, centre.dy);
  if (mystery) {
    final q =
        Path()
          ..moveTo(-radius * 0.28, -radius * 0.2)
          ..cubicTo(
            -radius * 0.3,
            -radius * 0.75,
            radius * 0.45,
            -radius * 0.7,
            radius * 0.3,
            -radius * 0.2,
          )
          ..quadraticBezierTo(radius * 0.2, 0, 0, radius * 0.12);
    canvas.drawPath(
      q,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.2
        ..color = glyph.color,
    );
    canvas.drawCircle(Offset(0, radius * 0.45), radius * 0.12, glyph);
  } else {
    canvas.drawPath(shapeOf(colour, radius * 0.48), glyph);
  }
  canvas.restore();
}
