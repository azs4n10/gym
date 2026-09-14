import 'package:flutter/material.dart';

/// A number that rolls up to its value when it first appears, and rolls to
/// the new value whenever it changes.
class CountUp extends StatelessWidget {
  const CountUp(
    this.value, {
    super.key,
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  final double value;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  String _format(double v) {
    if (decimals == 0) return v.round().toString();
    final s = v.toStringAsFixed(decimals);
    // Whole numbers lose their trailing zeros, as the rest of the app does.
    return s.endsWith('.${'0' * decimals}') ? s.substring(0, s.length - decimals - 1) : s;
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Text(_format(v), style: style),
      );
}
