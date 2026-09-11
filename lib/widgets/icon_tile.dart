import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// Rounded soft-colored square with an icon inside, as used in the quick-action
/// grid and list leadings.
class IconTile extends StatelessWidget {
  const IconTile(this.ic, {super.key, this.size = 44, this.color, this.iconColor});

  final Ic ic;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? skin.buttonSoft,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: skin.ink, width: kBorderWidth),
      ),
      child: AppIcon(ic, size: size * 0.52, color: iconColor),
    );
  }
}

/// Outlined round button, used for header actions and steppers.
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.background,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final enabled = onTap != null;
    return InkResponse(
      onTap: onTap,
      radius: size * 0.62,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background ?? skin.card,
            shape: BoxShape.circle,
            border: Border.all(color: skin.ink, width: size >= 34 ? 2 : 1.6),
          ),
          child: Icon(icon, size: size * 0.48, color: skin.ink),
        ),
      ),
    );
  }
}

/// Small circular "go" button used at the trailing edge of list cards.
class GoButton extends StatelessWidget {
  const GoButton({super.key, this.size = 34, this.icon = Icons.arrow_forward_rounded});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: skin.button,
        shape: BoxShape.circle,
        border: Border.all(color: skin.ink, width: 1.6),
      ),
      child: Icon(icon, size: size * 0.5, color: skin.ink),
    );
  }
}
