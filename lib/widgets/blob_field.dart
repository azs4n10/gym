import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft rounded masses for the inside of a panel: large discs that sit mostly
/// outside the frame so only a curved edge sweeps in, plus a few loose dots.
/// Arrangement is derived from [seed], so a panel always looks the same.
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
    final diag = math.sqrt(w * w + h * h);
    double rnd(double a, double b) => a + r.nextDouble() * (b - a);

    // Anchor each mass to a different side, centred well outside the frame, so
    // what shows is one broad curve rather than a shape crawling across it.
    final sides = [0, 1, 2, 3]..shuffle(r);
    final tones = [light, color, dark];
    for (var i = 0; i < 3; i++) {
      final radius = diag * rnd(0.5, 0.72);
      final along = rnd(0.15, 0.85);
      final depth = radius * rnd(0.78, 0.93);
      final centre = switch (sides[i]) {
        0 => Offset(w * along, -depth),
        1 => Offset(w + depth, h * along),
        2 => Offset(w * along, h + depth),
        _ => Offset(-depth, h * along),
      };
      canvas.drawCircle(centre, radius, Paint()..color = tones[i]);
    }

    // Loose dots, the way the reference layouts scatter them.
    for (var i = 0; i < (short > 110 ? 4 : 2); i++) {
      final dx = rnd(0.08, 0.92);
      final dy = rnd(0.1, 0.9);
      // Keep clear of the middle, where the icon sits.
      final x = (dx - 0.5).abs() < 0.28 ? (dx < 0.5 ? 0.12 : 0.88) : dx;
      final y = (dy - 0.5).abs() < 0.28 ? (dy < 0.5 ? 0.14 : 0.86) : dy;
      canvas.drawCircle(
        Offset(w * x, h * y),
        short * rnd(0.03, 0.06),
        Paint()..color = [light, dark, color][(i + seed) % 3],
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.seed != seed || old.color != color || old.light != light || old.dark != dark;
}
