import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';

import '../../ui/palette.dart';
import '../../ui/theme.dart';

/// What goes on the picture a player shares after passing a level. It holds
/// only game facts: no name, no device or account detail.
@immutable
class ShareCardData {
  const ShareCardData({
    required this.appName,
    required this.title,
    required this.headline,
    required this.stars,
    required this.tagline,
    this.detail,
  });

  final String appName;

  /// "Level 12", "Daily challenge"…
  final String title;

  /// "Level complete!"
  final String headline;
  final int stars;
  final String tagline;

  /// Optional small line, e.g. "7 flips".
  final String? detail;
}

/// 4:5 portrait, the size social feeds show without cropping.
const Size shareCardSize = Size(1080, 1350);

void paintShareCard(Canvas canvas, Size size, ShareCardData data) {
  final w = size.width;
  final h = size.height;
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

  // Soft pipes in the background, echoing the game board.
  final pipe =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.03
        ..color = AppColors.track.withAlpha(110);
  final root = Offset(w / 2, h * 0.3);
  for (final x in [0.14, 0.38, 0.62, 0.86]) {
    canvas.drawLine(root, Offset(w * x, h * 1.02), pipe);
  }

  // Row of tokens, the game's logo.
  const logo = [
    ItemColour.red,
    ItemColour.yellow,
    ItemColour.green,
    ItemColour.blue,
    ItemColour.purple,
  ];
  final r = w * 0.065;
  final gap = r * 2.5;
  final startX = w / 2 - gap * (logo.length - 1) / 2;
  for (var i = 0; i < logo.length; i++) {
    paintToken(canvas, Offset(startX + gap * i, h * 0.12), r, logo[i]);
  }

  // Single-line text shrinks to fit, so long or translated strings never
  // run into the stars; only the tagline may wrap.
  void text(
    String value,
    double y, {
    required double size,
    FontWeight weight = FontWeight.w800,
    Color colour = AppColors.text,
    double maxWidth = 0.84,
    int maxLines = 1,
  }) {
    TextPainter build(double fontSize) => TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: colour,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: w * maxWidth);

    var fontSize = size;
    var painter = build(fontSize);
    while (painter.didExceedMaxLines && fontSize > size * 0.45) {
      painter.dispose();
      fontSize *= 0.92;
      painter = build(fontSize);
    }
    painter.paint(canvas, Offset((w - painter.width) / 2, y));
    painter.dispose();
  }

  text(data.appName, h * 0.19, size: w * 0.105, weight: FontWeight.w900);

  // Result panel.
  final panel = RRect.fromRectAndRadius(
    Rect.fromLTWH(w * 0.08, h * 0.36, w * 0.84, h * 0.44),
    Radius.circular(w * 0.06),
  );
  canvas.drawRRect(
    panel.shift(Offset(0, h * 0.008)),
    Paint()..color = const Color(0x55000000),
  );
  canvas.drawRRect(panel, Paint()..color = AppColors.surface);

  text(
    data.title,
    h * 0.395,
    size: w * 0.05,
    weight: FontWeight.w700,
    colour: AppColors.textDim,
    maxWidth: 0.76,
  );
  text(data.headline, h * 0.445, size: w * 0.078, maxWidth: 0.76);

  final starR = w * 0.085;
  final starGap = starR * 2.5;
  final stars = data.stars.clamp(0, 3);
  for (var i = 0; i < 3; i++) {
    final centre = Offset(w / 2 + (i - 1) * starGap, h * 0.625);
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    final star = shapeOf(ItemColour.yellow, starR);
    if (i < stars) {
      canvas.drawPath(star, Paint()..color = AppColors.accent);
    } else {
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.track,
      );
    }
    canvas.restore();
  }

  if (data.detail case final detail?) {
    text(
      detail,
      h * 0.72,
      size: w * 0.045,
      weight: FontWeight.w700,
      colour: AppColors.textDim,
      maxWidth: 0.76,
    );
  }

  text(data.tagline, h * 0.865, size: w * 0.055, colour: AppColors.accent);
}

/// Draws the card off screen and returns it as PNG bytes.
Future<Uint8List> renderShareCard(ShareCardData data) async {
  final recorder = ui.PictureRecorder();
  paintShareCard(Canvas(recorder), shareCardSize, data);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    shareCardSize.width.round(),
    shareCardSize.height.round(),
  );
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}
