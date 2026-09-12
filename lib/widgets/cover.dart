import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'blob_field.dart';
import 'sticker.dart';
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
    this.seed = 0,
  });

  final Ic? ic;
  final Color tint;
  final double width;
  final double height;
  final double radius;
  final double? iconSize;
  final Widget? child;
  final bool outlined;

  /// Fixes which arrangement of shapes this panel gets.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return StickerBox(
      width: width,
      height: height,
      radius: radius,
      shadow: false,
      borderWidth: outlined ? kBorderWidth : 0,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: tint),
            if (width > 70)
              BlobField(
                color: Color.lerp(tint, skin.card, 0.3)!,
                light: Color.lerp(tint, skin.card, 0.62)!,
                dark: Color.lerp(tint, skin.ink, 0.22)!,
                seed: seed,
              ),
            if (child != null)
              Center(child: child)
            else if (ic != null)
              Center(
                child: AppIcon(ic!, size: iconSize ?? height * 0.42, color: skin.ink),
              ),
          ],
        ),
      ),
    );
  }
}

/// Square cover used as the leading element of a list row.
class CoverThumb extends StatelessWidget {
  const CoverThumb({
    super.key,
    required this.ic,
    required this.tint,
    this.size = 56,
    this.seed = 0,
  });

  final Ic ic;
  final Color tint;
  final double size;
  final int seed;

  @override
  Widget build(BuildContext context) => Cover(
        ic: ic,
        tint: tint,
        seed: seed,
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
        border: Border.all(color: skin.ink, width: kThinBorder),
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
