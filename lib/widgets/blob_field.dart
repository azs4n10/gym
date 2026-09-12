import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft rounded shapes for the inside of a panel: thick strokes with round
/// ends that wander across the box, plus a few loose dots. Arrangement is
/// derived from [seed], so a given panel always looks the same.
class BlobField extends StatelessWidget {
  const BlobField({
    super.key,
    required this.color,
    required this.light,
    required this.dark,
    this.seed = 0,
  });

  final Color color;
  final Color light;
  final Color dark;
  final int seed;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BlobPainter(color: color, light: light, dark: dark, seed: seed),
        isComplex: true,
        willChange: false,
      );
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({
    required this.color,
    required this.light,
    required this.dark,
    required this.seed,
  });

  final Color color;
  final Color light;
  final Color dark;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed * 7919 + 13);
    final w = size.width;
    final h = size.height;
    final short = math.min(w, h);
    double rnd(double a, double b) => a + r.nextDouble() * (b - a);
    final dense = short > 110;
    // The icon sits dead centre, so shapes are nudged out of the middle.
    Offset clear(double x, double y) {
      final dx = x - w / 2;
      final dy = y - h / 2;
      if ((dx.abs() / (w / 2)) < 0.55 && (dy.abs() / (h / 2)) < 0.55) {
        return Offset(
          w / 2 + (dx.isNegative ? -1 : 1) * w * 0.36,
          h / 2 + (dy.isNegative ? -1 : 1) * h * 0.36,
        );
      }
      return Offset(x, y);
    }

    Paint band(Color c, double weight) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = short * weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // A big soft shape bleeding off one corner, palest and furthest back.
    final corner = r.nextInt(4);
    final cx = (corner == 0 || corner == 3) ? -w * 0.1 : w * 1.1;
    final cy = corner < 2 ? -h * 0.15 : h * 1.15;
    canvas.drawCircle(Offset(cx, cy), short * rnd(0.62, 0.85), Paint()..color = light);

    // Two ribbons that enter from an edge and stop inside, so the round end
    // stays visible the way it does in the reference layouts.
    final ribbons = dense ? [(color, 0.24), (dark, 0.14)] : [(color, 0.2)];
    for (final (tone, weight) in ribbons) {
      final fromLeft = r.nextBool();
      final startX = fromLeft ? -short * 0.2 : w + short * 0.2;
      final start = clear(startX, h * rnd(0.08, 0.92));
      final end = clear(
        w * (fromLeft ? rnd(0.5, 0.88) : rnd(0.12, 0.5)),
        h * (r.nextBool() ? rnd(0.06, 0.24) : rnd(0.76, 0.94)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(startX, start.dy)
          ..cubicTo(
            startX + (end.dx - startX) * 0.4,
            start.dy - h * rnd(0.15, 0.45),
            startX + (end.dx - startX) * 0.7,
            end.dy + h * rnd(0.15, 0.45),
            end.dx,
            end.dy,
          ),
        band(tone, weight),
      );
    }

    // One short capsule floating free, both ends rounded.
    if (dense) {
      final p = clear(w * rnd(0.12, 0.88), h * rnd(0.12, 0.88));
      final len = short * rnd(0.26, 0.42);
      final angle = rnd(-0.9, 0.9);
      canvas.drawLine(
        p,
        Offset(p.dx + len * math.cos(angle), p.dy + len * math.sin(angle)),
        band(light, 0.11),
      );
    }

    // Loose dots, the way the reference layouts scatter them.
    for (var i = 0; i < (dense ? 4 : 2); i++) {
      final p = clear(w * rnd(0.08, 0.92), h * rnd(0.1, 0.9));
      canvas.drawCircle(
        p,
        short * rnd(0.028, 0.055),
        Paint()..color = [light, dark, color][i % 3],
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.seed != seed || old.color != color || old.light != light || old.dark != dark;
}
