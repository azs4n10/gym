import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../state/app_state.dart';

/// Small body diagram with the worked area filled in. Phosphor has no anatomy
/// glyphs, and the stand-ins for them (a heart for chest, a butterfly for back)
/// said nothing, so the group is shown on a body instead.
class MuscleMap extends StatelessWidget {
  const MuscleMap({
    super.key,
    required this.group,
    this.size = 24,
    this.bodyColor,
    this.markColor,
  });

  final MuscleGroup group;
  final double size;
  final Color? bodyColor;
  final Color? markColor;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MusclePainter(
          group: group,
          body: bodyColor ?? skin.ink.withValues(alpha: 0.22),
          mark: markColor ?? skin.ink,
        ),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _MusclePainter extends CustomPainter {
  const _MusclePainter({required this.group, required this.body, required this.mark});

  final MuscleGroup group;
  final Color body;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final pale = Paint()..color = body;
    final lit = Paint()..color = mark;

    // Front-facing silhouette, built from a few rounded blocks.
    canvas.drawCircle(const Offset(50, 15), 11, pale);
    canvas.drawRRect(
      RRect.fromLTRBR(33, 28, 67, 60, const Radius.circular(11)),
      pale,
    );
    for (final dx in [-1.0, 1.0]) {
      // arms
      canvas.drawRRect(
        RRect.fromLTRBR(
          50 + dx * 33 - (dx > 0 ? 0 : 8),
          30,
          50 + dx * 33 + (dx > 0 ? 8 : 0),
          64,
          const Radius.circular(5),
        ),
        pale,
      );
      // legs
      canvas.drawRRect(
        RRect.fromLTRBR(
          50 + dx * 12 - (dx > 0 ? 0 : 9),
          60,
          50 + dx * 12 + (dx > 0 ? 9 : 0),
          94,
          const Radius.circular(6),
        ),
        pale,
      );
    }

    switch (group) {
      case MuscleGroup.chest:
        for (final dx in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              50 + dx * 9 - (dx > 0 ? 1 : 7),
              31,
              50 + dx * 9 + (dx > 0 ? 7 : 1),
              43,
              const Radius.circular(4),
            ),
            lit,
          );
        }
      case MuscleGroup.back:
        // Lats: wide at the armpit, tapering to the waist, with the spine.
        for (final dx in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + dx * 16, 31)
              ..lineTo(50 + dx * 16, 44)
              ..lineTo(50 + dx * 4, 54)
              ..lineTo(50 + dx * 4, 38)
              ..close(),
            lit,
          );
        }
        canvas.drawRRect(
          RRect.fromLTRBR(48.5, 30, 51.5, 56, const Radius.circular(1.5)),
          lit,
        );
      case MuscleGroup.shoulders:
        for (final dx in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(50 + dx * 30, 34), 8, lit);
        }
      case MuscleGroup.arms:
        for (final dx in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              50 + dx * 33 - (dx > 0 ? 0 : 8),
              34,
              50 + dx * 33 + (dx > 0 ? 8 : 0),
              52,
              const Radius.circular(5),
            ),
            lit,
          );
        }
      case MuscleGroup.legs:
        for (final dx in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              50 + dx * 12 - (dx > 0 ? 0 : 9),
              62,
              50 + dx * 12 + (dx > 0 ? 9 : 0),
              80,
              const Radius.circular(6),
            ),
            lit,
          );
        }
      case MuscleGroup.glutes:
        canvas.drawRRect(
          RRect.fromLTRBR(35, 54, 65, 68, const Radius.circular(7)),
          lit,
        );
      case MuscleGroup.core:
        canvas.drawRRect(
          RRect.fromLTRBR(40, 42, 60, 60, const Radius.circular(5)),
          lit,
        );
    }
  }

  @override
  bool shouldRepaint(_MusclePainter old) =>
      old.group != group || old.body != body || old.mark != mark;
}
