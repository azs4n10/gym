import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/run_play.dart';

/// A landmark picture in the same ink-line style as the figures: strokes of
/// one colour on a small square, filled with a tint where it reads better.
class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.glyph, {super.key, this.size = 28, required this.ink, this.tint, this.dim = false});

  final Glyph glyph;
  final double size;
  final Color ink;
  final Color? tint;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(glyph, dim ? ink.withValues(alpha: 0.35) : ink, dim ? null : tint),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.ink, this.tint);
  final Glyph glyph;
  final Color ink;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = tint ?? Colors.transparent;
    Offset p(double x, double y) => Offset(x * u, y * u);
    Path poly(List<List<double>> pts, {bool close = true}) {
      final path = Path()..moveTo(pts.first[0] * u, pts.first[1] * u);
      for (final q in pts.skip(1)) {
        path.lineTo(q[0] * u, q[1] * u);
      }
      if (close) path.close();
      return path;
    }

    void shape(Path path) {
      if (tint != null) canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    switch (glyph) {
      case Glyph.flag:
        canvas.drawLine(p(6, 21), p(6, 3), stroke);
        shape(poly([[6, 4], [19, 7], [6, 11]]));
      case Glyph.goal:
        canvas.drawLine(p(5, 21), p(5, 3), stroke);
        shape(poly([[5, 4], [20, 4], [20, 12], [5, 12]]));
        final dark = Paint()..color = ink;
        for (var r = 0; r < 2; r++) {
          for (var c = 0; c < 3; c++) {
            if ((r + c).isEven) {
              canvas.drawRect(Rect.fromLTWH((5 + c * 5) * u, (4 + r * 4) * u, 5 * u, 4 * u), dark);
            }
          }
        }
      case Glyph.tree:
        canvas.drawLine(p(12, 21), p(12, 15), stroke);
        shape(poly([[12, 3], [19, 15], [5, 15]]));
        shape(poly([[12, 6], [17, 12], [7, 12]]));
      case Glyph.house:
        shape(poly([[5, 11], [5, 20], [19, 20], [19, 11]]));
        shape(poly([[3, 11], [12, 3], [21, 11]], close: false));
        canvas.drawRect(Rect.fromLTWH(10 * u, 14 * u, 4 * u, 6 * u), stroke);
      case Glyph.bridge:
        canvas.drawLine(p(2, 16), p(22, 16), stroke);
        final arc = Path()..moveTo(4 * u, 16 * u);
        arc.quadraticBezierTo(12 * u, 4 * u, 20 * u, 16 * u);
        canvas.drawPath(arc, stroke);
        for (final x in [8.0, 12.0, 16.0]) {
          canvas.drawLine(p(x, 16), p(x, 20), stroke);
        }
        canvas.drawLine(p(4, 20), p(20, 20), stroke);
      case Glyph.lighthouse:
        shape(poly([[9, 21], [10, 8], [14, 8], [15, 21]]));
        shape(poly([[8, 8], [16, 8], [14, 4], [10, 4]]));
        canvas.drawLine(p(4, 6), p(7, 6), stroke);
        canvas.drawLine(p(17, 6), p(20, 6), stroke);
        canvas.drawLine(p(7, 21), p(17, 21), stroke);
      case Glyph.spring:
        final bowl = Path()..moveTo(3 * u, 13 * u);
        bowl.lineTo(21 * u, 13 * u);
        bowl.quadraticBezierTo(21 * u, 21 * u, 12 * u, 21 * u);
        bowl.quadraticBezierTo(3 * u, 21 * u, 3 * u, 13 * u);
        shape(bowl);
        for (final x in [8.0, 12.0, 16.0]) {
          final s = Path()..moveTo(x * u, 10 * u);
          s.quadraticBezierTo((x + 2) * u, 7 * u, x * u, 4 * u);
          canvas.drawPath(s, stroke);
        }
      case Glyph.castle:
        shape(poly([[4, 21], [4, 9], [7, 9], [7, 6], [10, 6], [10, 9], [14, 9], [14, 6], [17, 6], [17, 9], [20, 9], [20, 21]]));
        canvas.drawRect(Rect.fromLTWH(10 * u, 14 * u, 4 * u, 7 * u), stroke);
      case Glyph.windmill:
        shape(poly([[9, 21], [10, 10], [14, 10], [15, 21]]));
        canvas.drawCircle(p(12, 10), 1.2 * u, Paint()..color = ink);
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + math.pi / 4;
          canvas.drawLine(p(12, 10), Offset(12 * u + math.cos(a) * 7 * u, 10 * u + math.sin(a) * 7 * u), stroke);
        }
      case Glyph.mountain:
        shape(poly([[2, 21], [9, 7], [13, 13], [16, 9], [22, 21]]));
        canvas.drawLine(p(7, 11), p(9, 7), stroke);
        canvas.drawLine(p(9, 7), p(11, 10), stroke);
      case Glyph.star:
        final pts = <List<double>>[];
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 9.0 : 4.0;
          final a = -math.pi / 2 + i * math.pi / 5;
          pts.add([12 + math.cos(a) * r, 12 + math.sin(a) * r]);
        }
        shape(poly(pts));
      case Glyph.moon:
        final moon = Path()..moveTo(15 * u, 3 * u);
        moon.arcToPoint(Offset(15 * u, 21 * u), radius: Radius.circular(9 * u), clockwise: false, largeArc: true);
        moon.arcToPoint(Offset(15 * u, 3 * u), radius: Radius.circular(7 * u), clockwise: true, largeArc: false);
        shape(moon);
      case Glyph.torii:
        canvas.drawLine(p(3, 6), p(21, 6), stroke);
        canvas.drawLine(p(5, 10), p(19, 10), stroke);
        canvas.drawLine(p(7, 6), p(7, 21), stroke);
        canvas.drawLine(p(17, 6), p(17, 21), stroke);
        canvas.drawLine(p(12, 6), p(12, 10), stroke);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.ink != ink || old.tint != tint;
}

/// The wheel: sectors in the theme colours with the call names around the
/// rim, a pointer at the top. [angle] is the current rotation in radians.
class RouletteWheel extends StatelessWidget {
  const RouletteWheel({
    super.key,
    required this.angle,
    required this.calls,
    required this.colors,
    required this.ink,
    required this.labelStyle,
    this.size = 200,
  });

  final double angle;
  final List<RouletteCall> calls;
  final List<Color> colors;
  final Color ink;
  final TextStyle labelStyle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WheelPainter(angle: angle, n: calls.length, colors: colors, ink: ink),
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              for (var i = 0; i < calls.length; i++)
                Center(
                  child: Transform.rotate(
                    angle: (i + 0.5) * 2 * math.pi / calls.length,
                    child: Transform.translate(
                      offset: Offset(0, -size * 0.36),
                      child: SizedBox(
                        width: size * 0.34,
                        child: Text(
                          calls[i].label(Localizations.localeOf(context).languageCode == 'ja'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.angle, required this.n, required this.colors, required this.ink});
  final double angle;
  final int n;
  final List<Color> colors;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: c, radius: r);
    final step = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawArc(rect, angle - math.pi / 2 + i * step, step, true, paint);
    }
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < n; i++) {
      final a = angle - math.pi / 2 + i * step;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * r, line);
    }
    canvas.drawCircle(c, r, line..strokeWidth = 2.4);
    canvas.drawCircle(c, 7, Paint()..color = ink);
    // Pointer at the top.
    final tip = Path()
      ..moveTo(c.dx - 9, 0)
      ..lineTo(c.dx + 9, 0)
      ..lineTo(c.dx, 18)
      ..close();
    canvas.drawPath(tip, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle || old.n != n;
}
