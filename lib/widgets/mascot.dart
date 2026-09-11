import 'package:flutter/material.dart';

import '../state/app_state.dart';

enum MascotMood { idle, happy, sleepy }

/// House mascot, drawn from shapes so it follows the skin colours and can hold
/// a few expressions without shipping artwork.
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
          inner: skin.accent,
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
    required this.inner,
    required this.mood,
  });

  final Color fill;
  final Color ink;
  final Color blush;
  final Color inner;
  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);

    final body = Paint()..color = fill;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final inkFill = Paint()..color = ink;

    // tail
    final tail = Path()
      ..moveTo(70, 86)
      ..cubicTo(90, 86, 94, 66, 84, 60);
    canvas.drawPath(tail, line);

    // torso
    final torso = RRect.fromLTRBR(30, 58, 70, 94, const Radius.circular(19));
    canvas.drawRRect(torso, body);
    canvas.drawRRect(torso, line);

    // ears
    for (final dir in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(50 + dir * 9, 26)
        ..lineTo(50 + dir * 25, 9)
        ..lineTo(50 + dir * 26, 33)
        ..close();
      canvas.drawPath(ear, body);
      canvas.drawPath(ear, line);
      final innerEar = Path()
        ..moveTo(50 + dir * 14, 25)
        ..lineTo(50 + dir * 22, 15)
        ..lineTo(50 + dir * 22, 28)
        ..close();
      canvas.drawPath(innerEar, Paint()..color = inner);
    }

    // head
    const head = Offset(50, 42);
    canvas.drawCircle(head, 26, body);
    canvas.drawCircle(head, 26, line);

    // blush
    final blushPaint = Paint()..color = blush;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(50 + dir * 17, 50), width: 11, height: 7),
        blushPaint,
      );
    }

    // eyes
    switch (mood) {
      case MascotMood.idle:
        for (final dir in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(50 + dir * 10, 41), 3.6, inkFill);
        }
      case MascotMood.happy:
        for (final dir in [-1.0, 1.0]) {
          final eye = Path()
            ..moveTo(50 + dir * 10 - 5, 43)
            ..quadraticBezierTo(50 + dir * 10, 35, 50 + dir * 10 + 5, 43);
          canvas.drawPath(eye, line);
        }
      case MascotMood.sleepy:
        for (final dir in [-1.0, 1.0]) {
          final eye = Path()
            ..moveTo(50 + dir * 10 - 5, 41)
            ..quadraticBezierTo(50 + dir * 10, 46, 50 + dir * 10 + 5, 41);
          canvas.drawPath(eye, line);
        }
    }

    // muzzle
    final mouth = Path()
      ..moveTo(45, 49)
      ..quadraticBezierTo(50, 54, 55, 49);
    canvas.drawPath(mouth, line);

    // whiskers
    for (final dir in [-1.0, 1.0]) {
      for (final dy in [-3.0, 3.0]) {
        canvas.drawLine(
          Offset(50 + dir * 24, 46 + dy),
          Offset(50 + dir * 34, 44 + dy * 1.6),
          line,
        );
      }
    }

    // paws
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(50 + dir * 11, 90), 6, body);
      canvas.drawCircle(Offset(50 + dir * 11, 90), 6, line);
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.mood != mood || old.fill != fill || old.ink != ink || old.blush != blush;
}
