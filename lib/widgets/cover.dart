import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'app_icon.dart';

/// Gradient panel that stands in for the photography used in the reference
/// layouts: a tinted field with the icon set large and faded behind it.
class Cover extends StatelessWidget {
  const Cover({
    super.key,
    required this.ic,
    required this.tint,
    this.width = 120,
    this.height = 104,
    this.radius = 22,
    this.iconScale = 0.62,
  });

  final Ic ic;
  final Color tint;
  final double width;
  final double height;
  final double radius;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final deep = Color.lerp(tint, skin.heading, 0.35)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
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
                  colors: [tint.withValues(alpha: 0.55), deep.withValues(alpha: 0.85)],
                ),
              ),
            ),
            Positioned(
              right: -height * 0.12,
              bottom: -height * 0.12,
              child: Opacity(
                opacity: 0.9,
                child: AppIcon(ic, size: height * iconScale, color: skin.card),
              ),
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
  Widget build(BuildContext context) =>
      Cover(ic: ic, tint: tint, width: size, height: size, radius: size * 0.32, iconScale: 0.5);
}

/// Small round button with a filled background, as used at the corner of the
/// workout cards in the reference layouts.
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
      decoration: BoxDecoration(color: background ?? skin.card, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: foreground ?? skin.heading),
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
