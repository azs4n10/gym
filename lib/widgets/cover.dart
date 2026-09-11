import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// Tinted panel that stands in for the photography used in the reference
/// layouts. It either centres an icon or shows whatever is passed as [child];
/// nothing is ever cropped by the rounded corners.
class Cover extends StatelessWidget {
  const Cover({
    super.key,
    this.ic,
    required this.tint,
    this.width = 120,
    this.height = 104,
    this.radius = 22,
    this.iconSize,
    this.child,
    this.outlined = true,
  });

  final Ic? ic;
  final Color tint;
  final double width;
  final double height;
  final double radius;
  final double? iconSize;
  final Widget? child;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final deep = Color.lerp(tint, skin.heading, 0.35)!;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: outlined ? Border.all(color: skin.ink, width: kBorderWidth) : null,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint.withValues(alpha: 0.6), deep.withValues(alpha: 0.9)],
                ),
              ),
            ),
            if (child != null)
              Center(child: child)
            else if (ic != null)
              Center(
                child: AppIcon(ic!, size: iconSize ?? height * 0.42, color: skin.card),
              ),
          ],
        ),
      ),
    );
  }
}

/// Square cover used as the leading element of a list row.
class CoverThumb extends StatelessWidget {
  const CoverThumb({super.key, required this.ic, required this.tint, this.size = 56});

  final Ic ic;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) => Cover(
        ic: ic,
        tint: tint,
        width: size,
        height: size,
        radius: size * 0.32,
        iconSize: size * 0.46,
      );
}

/// Small round button with a filled background, as used at the corner of the
/// cards in the reference layouts.
class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    this.icon = Icons.arrow_forward_rounded,
    this.size = 34,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? skin.card,
        shape: BoxShape.circle,
        border: Border.all(color: skin.ink, width: 1.6),
      ),
      child: Icon(icon, size: size * 0.5, color: foreground ?? skin.ink),
    );
  }
}

/// Label above a bold value, three of which sit in a row under the hero on the
/// reference detail screen.
class MetricColumn extends StatelessWidget {
  const MetricColumn({super.key, required this.label, required this.value, this.onCover = false});

  final String label;
  final String value;
  final bool onCover;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final base = onCover ? skin.buttonText : skin.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: t.labelSmall?.copyWith(
                color: base.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: t.titleMedium?.copyWith(
                color: onCover ? skin.buttonText : skin.heading, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
