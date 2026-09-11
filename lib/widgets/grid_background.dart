import 'package:flutter/material.dart';

import '../theme/skin.dart';

/// Grid-paper backdrop that sits behind every screen.
class GridBackground extends StatelessWidget {
  const GridBackground({super.key, required this.skin, required this.child});

  final Skin skin;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: skin.background),
        child: CustomPaint(
          painter: _GridPainter(skin.grid),
          child: child,
        ),
      );
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.line);

  final Color line;
  static const double _step = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.line != line;
}
