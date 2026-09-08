import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../state/app_state.dart';

class GroupBadge extends StatelessWidget {
  const GroupBadge(this.group, {super.key, this.size = 26});

  final MuscleGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final ink = HSLColor.fromColor(group.color).withLightness(0.36).withSaturation(0.45).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Text(
        group.shortCode(l),
        style: TextStyle(
          fontSize: size * (l.isJa ? 0.5 : 0.38),
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1,
        ),
      ),
    );
  }
}

IconData moodIcon(int mood) => switch (mood) {
      1 => Icons.sentiment_very_dissatisfied_rounded,
      2 => Icons.sentiment_dissatisfied_rounded,
      3 => Icons.sentiment_neutral_rounded,
      4 => Icons.sentiment_satisfied_rounded,
      _ => Icons.sentiment_very_satisfied_rounded,
    };
