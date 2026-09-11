import 'package:flutter/material.dart';

import '../state/app_state.dart';

enum MascotMood { idle, happy, sleepy }

/// House mascot, drawn from shapes so it follows the skin colours and can hold
/// a few expressions without shipping artwork. Modelled on the reference cat:
/// heavy outline, one lilac patch, closed eyes and a raised paw.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 96, this.mood = MascotMood.idle});

  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(
          fill: skin.card,
          ink: skin.ink,
          blush: skin.button,
          patch: skin.accent,
          mood: mood,
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({
    required this.fill,
    required this.ink,
    required this.blush,
    required this.patch,
    required this.mood,
  });

  final Color fill;
  final Color ink;
  final Color blush;
  final Color patch;
  final MascotMood mood;

  static const Offset _head = Offset(48, 50);
  static const double _headR = 30;

  /// Wavy lower edge of the head patch.
  static final Path _capEdge = Path()
    ..moveTo(12, 40)
    ..quadraticBezierTo(26, 31, 38, 38)
    ..quadraticBezierTo(50, 45, 62, 35)
    ..quadraticBezierTo(73, 28, 84, 36);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);

    final body = Paint()..color = fill;
    final patchPaint = Paint()..color = patch;
    final blushPaint = Paint()..color = blush;
    final inkFill = Paint()..color = ink;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    _paw(canvas, body, line, blushPaint);
    _ears(canvas, patchPaint, line);

    // head, with the lilac cap sitting over the top like the reference sheet
    canvas.drawCircle(_head, _headR, body);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: _head, radius: _headR)));
    canvas.drawPath(
      Path.from(_capEdge)
        ..lineTo(84, 12)
        ..lineTo(12, 12)
        ..close(),
      patchPaint,
    );
    canvas.drawPath(_capEdge, line);
    canvas.restore();
    canvas.drawCircle(_head, _headR, line);

    _face(canvas, line, inkFill, blushPaint);
  }

  void _ears(Canvas canvas, Paint patchPaint, Paint line) {
    final left = Path()
      ..moveTo(26, 34)
      ..lineTo(16, 6)
      ..lineTo(44, 20)
      ..close();
    final right = Path()
      ..moveTo(70, 34)
      ..lineTo(80, 6)
      ..lineTo(52, 20)
      ..close();
    canvas.drawPath(left, patchPaint);
    canvas.drawPath(right, patchPaint);
    canvas.drawPath(left, line);
    canvas.drawPath(right, line);
  }

  void _face(Canvas canvas, Paint line, Paint inkFill, Paint blushPaint) {
    const eyeY = 48.0;
    const left = 34.0;
    const right = 62.0;

    switch (mood) {
      case MascotMood.idle:
        for (final x in [left, right]) {
          canvas.drawPath(
            Path()
              ..moveTo(x - 8, eyeY + 3)
              ..quadraticBezierTo(x, eyeY - 9, x + 8, eyeY + 3),
            line,
          );
        }
      case MascotMood.happy:
        for (final x in [left, right]) {
          canvas.drawCircle(Offset(x, eyeY), 4.6, inkFill);
          canvas.drawCircle(Offset(x - 1.4, eyeY - 1.8), 1.5, Paint()..color = Colors.white);
        }
      case MascotMood.sleepy:
        for (final x in [left, right]) {
          canvas.drawPath(
            Path()
              ..moveTo(x - 8, eyeY - 1)
              ..quadraticBezierTo(x, eyeY + 7, x + 8, eyeY - 1),
            line,
          );
        }
    }

    // w-shaped mouth
    canvas.drawPath(
      Path()
        ..moveTo(41, 60)
        ..quadraticBezierTo(45, 66, 48, 60)
        ..quadraticBezierTo(51, 66, 55, 60),
      line,
    );

    // muzzle blush
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(48, 68), width: 9, height: 5),
      blushPaint,
    );

    // cheeks
    for (final x in [27.0, 69.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 58), width: 12, height: 7.5),
        blushPaint,
      );
    }

    if (mood == MascotMood.happy) _star(canvas, const Offset(9, 26), 8, line);
  }

  /// Four-point sparkle, the one sticker the mascot carries itself.
  void _star(Canvas canvas, Offset c, double r, Paint line) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.2, c.dy - r * 0.2, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.2, c.dy + r * 0.2, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.2, c.dy + r * 0.2, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.2, c.dy - r * 0.2, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = blush);
    canvas.drawPath(path, line);
  }

  void _paw(Canvas canvas, Paint body, Paint line, Paint blushPaint) {
    final paw = RRect.fromLTRBR(64, 60, 92, 98, const Radius.circular(14));
    canvas.drawRRect(paw, body);
    canvas.drawRRect(paw, line);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(78, 84), width: 14, height: 12),
      blushPaint,
    );
    for (final dx in [-6.5, 0.0, 6.5]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(78 + dx, 72), width: 6, height: 7),
        blushPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.mood != mood ||
      old.fill != fill ||
      old.ink != ink ||
      old.blush != blush ||
      old.patch != patch;
}
