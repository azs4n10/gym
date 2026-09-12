import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// How far the hard shadow sits below and right of a sticker surface. Pressing
/// moves the surface by exactly this much, so it lands on its own shadow.
const Offset kStickerOffset = Offset(3, 4);

/// The one outlined surface every card, tile and button is built from: border,
/// hard shadow, and a clip that stops the fill painting over the border.
class StickerBox extends StatefulWidget {
  const StickerBox({
    super.key,
    required this.child,
    this.radius = kCardRadius,
    this.color,
    this.borderColor,
    this.borderWidth = kBorderWidth,
    this.shadow = true,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  State<StickerBox> createState() => _StickerBoxState();
}

class _StickerBoxState extends State<StickerBox> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final sunk = _down && widget.shadow;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      transform: Matrix4.translationValues(
        _down ? kStickerOffset.dx : 0,
        _down ? kStickerOffset.dy : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: widget.color ?? skin.card,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.borderWidth <= 0
            ? null
            : Border.all(color: widget.borderColor ?? skin.ink, width: widget.borderWidth),
        boxShadow: [
          BoxShadow(
            color: sunk ? Colors.transparent : skin.shadow,
            blurRadius: 0,
            offset: sunk ? Offset.zero : kStickerOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius - widget.borderWidth),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: Semantics(button: true, child: box),
    );
  }
}

/// Wraps each real entry of a page's scroll view in [Appear], leaving plain
/// spacers alone, so the page settles in from the top.
List<Widget> staggered(List<Widget> children) {
  var i = 0;
  return [
    for (final c in children)
      if (c is SizedBox) c else Appear(index: i++, child: c),
  ];
}

/// Fades and lifts its child into place once, [index] steps after the screen
/// appears, so a page settles top to bottom instead of snapping in.
class Appear extends StatefulWidget {
  const Appear({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 30 * widget.index.clamp(0, 10));
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (_, child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(offset: Offset(0, 12 * (1 - _t.value)), child: child),
        ),
        child: widget.child,
      );
}
