import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'sticker.dart';

/// Card framed like an old desktop window: a tinted title bar with the name on
/// the left and three round buttons on the right, over an outlined body.
/// The buttons do what their colours suggest on a desktop: the pale one folds
/// the panel away, the middle one recolours the bar, the dark one opens the
/// panel full screen.
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
  int _tintStep = 0;

  Color _bar(BuildContext context) {
    final skin = context.skin;
    final base = widget.tint ?? skin.button;
    return switch (_tintStep % 3) {
      0 => base,
      1 => skin.accent,
      _ => Color.lerp(skin.heading, skin.card, 0.45)!,
    };
  }

  void _openFull(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final bar = _bar(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, a, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: bar,
            foregroundColor: skin.ink,
            title: Text(
              widget.title,
              style: t.titleMedium?.copyWith(color: skin.ink, fontWeight: FontWeight.w800),
            ),
            shape: Border(bottom: BorderSide(color: skin.ink, width: kBorderWidth)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: widget.child,
          ),
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final bar = _bar(context);

    return StickerBox(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
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
                else ...[
                  _WindowDot(
                    color: skin.card,
                    glowColor: skin.button,
                    lit: _folded,
                    onTap: () => setState(() => _folded = !_folded),
                  ),
                  _WindowDot(
                    color: skin.accent,
                    glowColor: skin.accent,
                    lit: _tintStep % 3 != 0,
                    onTap: () => setState(() => _tintStep++),
                  ),
                  _WindowDot(
                    color: skin.heading,
                    glowColor: skin.heading,
                    lit: false,
                    onTap: () => _openFull(context),
                  ),
                ],
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

/// One of the three buttons on a title bar. Lights up while held, and stays
/// lit while whatever it controls is switched on.
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
      // The dot is small by design; the area that answers a finger is not.
      child: SizedBox(
        width: 30,
        height: 30,
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
