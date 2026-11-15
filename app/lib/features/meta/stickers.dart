import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/game_store.dart';

const int stickersPerSet = 12;

/// Sticker set themes, in album order. A set boundary falls every 12 levels.
const List<({String en, String hi})> stickerSets = [
  (en: 'Ocean Pals', hi: 'समुद्री दोस्त'),
  (en: 'Forest Friends', hi: 'जंगल के दोस्त'),
  (en: 'Space Buddies', hi: 'अंतरिक्ष के साथी'),
  (en: 'Candy Critters', hi: 'मीठे जीव'),
  (en: 'Desert Dwellers', hi: 'रेगिस्तान के वासी'),
  (en: 'Arctic Chums', hi: 'बर्फ़ीले यार'),
  (en: 'Jungle Gang', hi: 'जंगल टोली'),
  (en: 'Garden Bugs', hi: 'बगीचे के कीड़े'),
  (en: 'Sky Flyers', hi: 'आसमानी उड़ाके'),
  (en: 'Robo Pals', hi: 'रोबो दोस्त'),
  (en: 'Dino Crew', hi: 'डायनो टोली'),
  (en: 'Monster Mash', hi: 'राक्षस मंडली'),
  (en: 'Farm Folk', hi: 'खेत के साथी'),
  (en: 'Night Owls', hi: 'रात के उल्लू'),
  (en: 'Fruit Bunch', hi: 'फलों का गुच्छा'),
  (en: 'Music Makers', hi: 'संगीत मंडली'),
  (en: 'Sporty Bunch', hi: 'खिलाड़ी टोली'),
  (en: 'Wizard Kin', hi: 'जादूगर परिवार'),
  (en: 'Pirate Crew', hi: 'समुद्री डाकू दल'),
  (en: 'Festival Friends', hi: 'त्योहार के दोस्त'),
];

String stickerSetName(int setIndex, String languageCode) {
  if (setIndex < stickerSets.length) {
    final s = stickerSets[setIndex];
    return languageCode == 'hi' ? s.hi : s.en;
  }
  final n = setIndex - stickerSets.length + 1;
  return languageCode == 'hi' ? 'बोनस सेट $n' : 'Bonus Set $n';
}

int ownedInSet(Set<StickerKey> owned, int setIndex) =>
    owned.where((s) => s.set == setIndex).length;

/// The set currently being collected: the first one that is not complete.
int currentSetIndex(Set<StickerKey> owned) {
  var set = 0;
  while (ownedInSet(owned, set) >= stickersPerSet) {
    set++;
  }
  return set;
}

/// One sticker pull from the current set. Never a duplicate: it picks among
/// the stickers still missing from that set (plan §2.4).
StickerKey pullSticker(Set<StickerKey> owned, math.Random rng) {
  final set = currentSetIndex(owned);
  final missing = [
    for (var i = 0; i < stickersPerSet; i++)
      if (!owned.contains((set: set, index: i))) i,
  ];
  return (set: set, index: missing[rng.nextInt(missing.length)]);
}

/// Whether adding [pulled] to [owned] finishes its set.
bool completesSet(Set<StickerKey> owned, StickerKey pulled) =>
    !owned.contains(pulled) &&
    ownedInSet(owned, pulled.set) == stickersPerSet - 1;

/// Placeholder sticker art: a small creature drawn from shapes, different
/// for every (set, index). Swap for artist sprites when they arrive.
class StickerPainter extends CustomPainter {
  StickerPainter({required this.set, required this.index, this.owned = true});

  final int set;
  final int index;
  final bool owned;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(set * 1000 + index * 37 + 11);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final hue = (set * 47.0 + index * 29.0 + rng.nextInt(20)) % 360;
    final body =
        owned
            ? HSLColor.fromAHSL(1, hue, 0.68, 0.58).toColor()
            : const Color(0xFF3A4686);
    final dark =
        owned
            ? HSLColor.fromAHSL(1, hue, 0.7, 0.36).toColor()
            : const Color(0xFF2B3570);
    final paint = Paint()..color = body;
    final darkPaint = Paint()..color = dark;

    // Backing disc.
    canvas.drawCircle(
      c,
      r * 0.96,
      Paint()
        ..color =
            owned
                ? HSLColor.fromAHSL(1, (hue + 180) % 360, 0.5, 0.9).toColor()
                : const Color(0xFF263168),
    );

    final variant = (set + index) % 4;
    final bodyRect = Rect.fromCenter(
      center: c + Offset(0, r * 0.12),
      width: r * (1.05 + rng.nextDouble() * 0.2),
      height: r * (0.95 + rng.nextDouble() * 0.25),
    );

    // Ears / horns / fins behind the body.
    final earY = bodyRect.top + r * 0.1;
    switch ((set + index * 3) % 5) {
      case 0: // round ears
        canvas.drawCircle(
          Offset(bodyRect.left + r * 0.18, earY),
          r * 0.2,
          darkPaint,
        );
        canvas.drawCircle(
          Offset(bodyRect.right - r * 0.18, earY),
          r * 0.2,
          darkPaint,
        );
      case 1: // pointed ears
        for (final sx in [-1.0, 1.0]) {
          final x = c.dx + sx * bodyRect.width * 0.3;
          canvas.drawPath(
            Path()
              ..moveTo(x - r * 0.16, earY + r * 0.1)
              ..lineTo(x + sx * r * 0.08, earY - r * 0.34)
              ..lineTo(x + r * 0.16, earY + r * 0.1)
              ..close(),
            darkPaint,
          );
        }
      case 2: // antennae
        for (final sx in [-1.0, 1.0]) {
          final tip = Offset(c.dx + sx * r * 0.3, bodyRect.top - r * 0.22);
          canvas.drawLine(
            Offset(c.dx + sx * r * 0.14, bodyRect.top + r * 0.1),
            tip,
            Paint()
              ..color = dark
              ..strokeWidth = r * 0.06
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawCircle(tip, r * 0.08, darkPaint);
        }
      case 3: // side fins
        for (final sx in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(c.dx + sx * bodyRect.width * 0.52, c.dy + r * 0.2),
              width: r * 0.3,
              height: r * 0.42,
            ),
            darkPaint,
          );
        }
      default: // tuft
        canvas.drawCircle(Offset(c.dx, bodyRect.top), r * 0.16, darkPaint);
    }

    switch (variant) {
      case 0:
        canvas.drawOval(bodyRect, paint);
      case 1:
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, Radius.circular(r * 0.32)),
          paint,
        );
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(bodyRect.left, bodyRect.bottom)
            ..quadraticBezierTo(
              bodyRect.left,
              bodyRect.top - r * 0.2,
              c.dx,
              bodyRect.top,
            )
            ..quadraticBezierTo(
              bodyRect.right,
              bodyRect.top - r * 0.2,
              bodyRect.right,
              bodyRect.bottom,
            )
            ..close(),
          paint,
        );
      default:
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            bodyRect,
            topLeft: Radius.circular(r * 0.5),
            topRight: Radius.circular(r * 0.5),
            bottomLeft: Radius.circular(r * 0.18),
            bottomRight: Radius.circular(r * 0.18),
          ),
          paint,
        );
    }

    if (!owned) {
      final tp = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: r * 0.7,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF7B86B3),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c + Offset(-tp.width / 2, r * 0.12 - tp.height / 2));
      return;
    }

    // Belly patch.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.38),
        width: bodyRect.width * 0.5,
        height: bodyRect.height * 0.36,
      ),
      Paint()..color = Colors.white.withAlpha(70),
    );

    // Eyes.
    final eyeY = c.dy - r * 0.02;
    final eyeGap = r * (0.2 + rng.nextDouble() * 0.08);
    final eyeR = r * (0.11 + rng.nextDouble() * 0.05);
    final oneEye = (set * 7 + index) % 9 == 0;
    for (final sx in oneEye ? [0.0] : [-1.0, 1.0]) {
      final e = Offset(c.dx + sx * eyeGap, eyeY);
      canvas.drawCircle(
        e,
        eyeR * (oneEye ? 1.5 : 1),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        e + Offset(eyeR * 0.15, eyeR * 0.1),
        eyeR * 0.55 * (oneEye ? 1.5 : 1),
        Paint()..color = const Color(0xFF1B2452),
      );
    }

    // Mouth.
    final mouth =
        Paint()
          ..color = const Color(0xFF1B2452)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..strokeCap = StrokeCap.round;
    final my = c.dy + r * 0.26;
    if (index.isEven) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx, my - r * 0.06),
          width: r * 0.3,
          height: r * 0.22,
        ),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        mouth,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, my),
          width: r * 0.16,
          height: r * 0.12,
        ),
        Paint()..color = const Color(0xFF1B2452),
      );
    }

    // Cheeks.
    for (final sx in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(c.dx + sx * (eyeGap + r * 0.14), eyeY + r * 0.2),
        r * 0.07,
        Paint()..color = const Color(0x55FF6B9D),
      );
    }
  }

  @override
  bool shouldRepaint(StickerPainter old) =>
      old.set != set || old.index != index || old.owned != owned;
}

class StickerView extends StatelessWidget {
  const StickerView({
    super.key,
    required this.set,
    required this.index,
    this.owned = true,
    this.size = 64,
  });

  final int set;
  final int index;
  final bool owned;
  final double size;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(size),
      painter: StickerPainter(set: set, index: index, owned: owned),
    ),
  );
}
