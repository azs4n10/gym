import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'emo.dart';

class GroupBadge extends StatelessWidget {
  const GroupBadge(this.group, {super.key, this.size = 28});

  final MuscleGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: EmoIcon(group.emo, size: size * 0.68),
    );
  }
}
