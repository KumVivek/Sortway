import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';

import 'palette.dart';
import 'theme.dart';

/// The Flow Sort mark: a belt that splits at a switch, with a red item being
/// routed down the lit branch towards its bin.
///
/// [background] paints the navy gradient; launch screens and Android's
/// adaptive-icon foreground leave it off. [scale] shrinks the art about the
/// centre, for the adaptive icon's safe zone.
void paintAppIcon(
  Canvas canvas,
  Size size, {
  bool background = true,
  double scale = 1,
}) {
  final s = size.shortestSide;
  if (background) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ).createShader(rect),
    );
  }

  canvas.save();
  canvas.translate(size.width / 2, size.height / 2);
  canvas.scale(scale * s);
  canvas.translate(-0.5, -0.5);

  // From here on, coordinates are fractions of the icon (0..1).
  const top = Offset(0.5, 0.13);
  const node = Offset(0.5, 0.45);
  const left = Offset(0.25, 0.78);
  const right = Offset(0.75, 0.78);

  Paint pipe(Color c, double width) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = c;

  // Dark outline under the pipes so they read on any wallpaper.
  final outline = pipe(const Color(0x66000000), 0.115);
  for (final end in [left, right]) {
    canvas.drawLine(node, end, outline);
  }
  canvas.drawLine(top, node, outline);

  canvas.drawLine(node, right, pipe(AppColors.track, 0.085));
  canvas.drawLine(top, node, pipe(AppColors.trackActive, 0.085));
  canvas.drawLine(node, left, pipe(AppColors.trackActive, 0.085));

  // Bins at the ends of the branches.
  void bin(Offset at, ItemColour colour) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at + const Offset(0, 0.05), width: 0.27, height: 0.17),
      const Radius.circular(0.05),
    );
    canvas.drawRRect(r.shift(const Offset(0, 0.015)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(r, Paint()..color = AppColors.surface);
    canvas.drawRRect(
      r.deflate(0.018),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.022
        ..color = colourOf(colour),
    );
  }

  bin(left, ItemColour.red);
  bin(right, ItemColour.blue);

  // The switch: a disc with an arrow pointing down the lit branch.
  canvas.drawCircle(node + const Offset(0, 0.012), 0.105, Paint()..color = const Color(0x66000000));
  canvas.drawCircle(node, 0.105, Paint()..color = AppColors.accent);
  final dir = (left - node) / (left - node).distance;
  final perp = Offset(-dir.dy, dir.dx);
  final ink = Paint()..color = AppColors.onAccent;
  canvas.drawLine(
    node - dir * 0.06,
    node + dir * 0.02,
    pipe(AppColors.onAccent, 0.032),
  );
  final tip = node + dir * 0.078;
  final b1 = node + dir * 0.01 + perp * 0.048;
  final b2 = node + dir * 0.01 - perp * 0.048;
  canvas.drawPath(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close(),
    ink,
  );

  // Items: a red one riding the lit branch, a blue one waiting in its bin,
  // and a yellow one entering at the top.
  paintToken(canvas, Offset.lerp(node, left, 0.52)!, 0.085, ItemColour.red);
  paintToken(canvas, right + const Offset(0, 0.045), 0.062, ItemColour.blue);
  paintToken(canvas, Offset.lerp(top, node, 0.18)!, 0.07, ItemColour.yellow);

  canvas.restore();
}
