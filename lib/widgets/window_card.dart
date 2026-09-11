import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Card framed like an old desktop window: a tinted title bar with the name on
/// the left and three round buttons on the right, over an outlined body.
class WindowCard extends StatelessWidget {
  const WindowCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final bar = tint ?? skin.button;
    final shape = BorderRadius.circular(kCardRadius);

    return Container(
      decoration: BoxDecoration(
        color: skin.card,
        borderRadius: shape,
        border: Border.all(color: skin.ink, width: kBorderWidth),
        boxShadow: [
          BoxShadow(color: skin.shadow, blurRadius: 0, offset: const Offset(3, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
                decoration: BoxDecoration(
                  color: bar,
                  border: Border(bottom: BorderSide(color: skin.ink, width: kBorderWidth)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelLarge?.copyWith(
                          color: skin.ink,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing! else const _WindowButtons(),
                  ],
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in [skin.card, skin.accent, skin.heading])
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: skin.ink, width: 1.4),
            ),
          ),
      ],
    );
  }
}
