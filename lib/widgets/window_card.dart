import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'sticker.dart';

/// Card framed like an old desktop window: a tinted title bar with the name on
/// the left and three round buttons on the right, over an outlined body.
class WindowCard extends StatefulWidget {
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
  State<WindowCard> createState() => _WindowCardState();
}

class _WindowCardState extends State<WindowCard> {
  bool _folded = false;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final bar = widget.tint ?? skin.button;

    return StickerBox(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 3, 6, 3),
            decoration: BoxDecoration(
              color: bar,
              border: Border(bottom: BorderSide(color: skin.ink, width: kBorderWidth)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge?.copyWith(
                      color: skin.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (widget.trailing != null)
                  widget.trailing!
                else
                  _WindowButtons(
                    folded: _folded,
                    onTap: () => setState(() => _folded = !_folded),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _folded
                ? const SizedBox(width: double.infinity)
                : Padding(padding: widget.padding, child: widget.child),
          ),
        ],
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons({required this.folded, required this.onTap});

  final bool folded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The pale dot needs a tinted halo of its own, or its glow vanishes.
        for (final (fill, glow) in [
          (skin.card, skin.button),
          (skin.accent, skin.accent),
          (skin.heading, skin.heading),
        ])
          _WindowDot(color: fill, glowColor: glow, lit: folded, onTap: onTap),
      ],
    );
  }
}

/// One of the three buttons on a title bar. Lights up while held, and stays
/// lit while the panel is folded away.
class _WindowDot extends StatefulWidget {
  const _WindowDot({
    required this.color,
    required this.glowColor,
    required this.lit,
    required this.onTap,
  });

  final Color color;
  final Color glowColor;
  final bool lit;
  final VoidCallback onTap;

  @override
  State<_WindowDot> createState() => _WindowDotState();
}

class _WindowDotState extends State<_WindowDot> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final glow = _down || widget.lit;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: SizedBox(
        width: 24,
        height: 26,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: _down ? 13 : 11,
            height: _down ? 13 : 11,
            decoration: BoxDecoration(
              color: glow ? Color.lerp(widget.color, widget.glowColor, 0.55) : widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: skin.ink, width: kThinBorder),
              boxShadow: [
                BoxShadow(
                  color: glow ? widget.glowColor : Colors.transparent,
                  blurRadius: glow ? 8 : 0,
                  spreadRadius: glow ? 2 : 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
