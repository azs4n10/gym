import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import 'app_icon.dart';

class GroupBadge extends StatelessWidget {
  const GroupBadge(this.group, {super.key, this.size = 28});

  final MuscleGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: group.color,
        shape: BoxShape.circle,
        border: Border.all(color: skin.ink, width: 1.4),
      ),
      child: AppIcon(group.ic, size: size * 0.62, color: skin.ink),
    );
  }
}
