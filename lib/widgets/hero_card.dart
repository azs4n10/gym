import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Gradient card with soft decorative circles, used as the page hero.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final a = skin.button;
    final b = Color.lerp(skin.accent, skin.heading, 0.25)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: skin.ink, width: kBorderWidth),
        boxShadow: [
          BoxShadow(color: skin.shadow, blurRadius: 0, offset: const Offset(3, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius - kBorderWidth),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [a, b],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -40,
                    child: _Blob(size: 150, color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  Positioned(
                    right: 60,
                    bottom: -50,
                    child: _Blob(size: 110, color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Page title row used instead of an AppBar on tab pages.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: skin.heading,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
