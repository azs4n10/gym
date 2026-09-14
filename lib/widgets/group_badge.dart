import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

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
      decoration: BoxDecoration(
        color: group.color(skin),
        shape: BoxShape.circle,
        border: Border.all(color: skin.ink, width: kThinBorder),
      ),
    );
  }
}
