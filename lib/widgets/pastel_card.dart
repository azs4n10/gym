import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// Sticker-style surface: pastel fill, ink outline, hard offset shadow.
class PastelCard extends StatelessWidget {
  const PastelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.borderColor,
    this.radius = kCardRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final shape = BorderRadius.circular(radius);
    final body = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: color ?? skin.card,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? skin.ink, width: kBorderWidth),
        boxShadow: [
          BoxShadow(color: skin.shadow, blurRadius: 0, offset: const Offset(3, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.ic, this.trailing});

  final String text;
  final IconData? icon;
  final Ic? ic;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          if (ic != null) ...[
            AppIcon(ic!, size: 20),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 18, color: skin.heading),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: skin.heading,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, this.icon, this.ic, required this.text});

  final IconData? icon;
  final Ic? ic;
  final String text;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ic != null)
              AppIcon(ic!, size: 40, color: skin.subText)
            else
              Icon(icon, size: 36, color: skin.divider),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: skin.subText, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.ic,
    this.color,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Ic? ic;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    return PastelCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (ic != null) ...[
                AppIcon(ic!, size: 16, color: skin.subText),
                const SizedBox(width: 4),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: skin.subText),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelMedium?.copyWith(color: skin.subText, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: t.headlineSmall?.copyWith(
                  color: skin.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit!, style: t.labelMedium?.copyWith(color: skin.subText)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
