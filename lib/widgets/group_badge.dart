import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'muscle_map.dart';

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
        color: group.color(skin),
        shape: BoxShape.circle,
        border: Border.all(color: skin.ink, width: kThinBorder),
      ),
      child: size < 24 ? null : MuscleMap(group: group, size: size * 0.78),
    );
  }
}
