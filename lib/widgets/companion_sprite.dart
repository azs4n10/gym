import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'exercise_figure.dart';
import 'run_scene.dart';

/// The illustrated companion: one drawing per pose in assets/companion,
/// two of them swapped for a stride, the whole body bobbing and leaning a
/// little with the pace. Which drawing shows follows the same state the
/// stick figure uses (view, resting, expression).
class CompanionSprite extends StatelessWidget {
  const CompanionSprite({
    super.key,
    required this.view,
    required this.resting,
    required this.face,
    required this.phase,
    required this.speed,
    required this.height,
  });

  final SceneView view;
  final bool resting;
  final FigureFace face;

  /// Stride phase in cycles; a new frame every half cycle.
  final double phase;
  final double speed;
  final double height;

  static const folder = 'assets/companion';

  /// Every file the companion can show, for the worker to keep on the device.
  static const files = [
    'run_side_a', 'run_side_b', 'sit_side', 'run_side_tired', 'run_side_closed',
    'run_back_a', 'run_back_b', 'stand_back',
  ];

  String get _frame {
    final second = (phase * 2).floor().isOdd;
    if (view == SceneView.ahead) {
      if (resting) return 'stand_back';
      return second ? 'run_back_b' : 'run_back_a';
    }
    if (resting) return 'sit_side';
    if (face == FigureFace.push) return second ? 'run_side_b' : 'run_side_tired';
    if (face == FigureFace.rest) return 'run_side_closed';
    return second ? 'run_side_b' : 'run_side_a';
  }

  @override
  Widget build(BuildContext context) {
    final moving = !resting;
    // A small bounce on every footfall, and a lean into the pace.
    final bob = moving ? -height * 0.03 * math.sin(math.pi * (phase * 2 % 1)).abs() : 0.0;
    final lean = moving && view == SceneView.side ? 0.06 * (speed / 12).clamp(0.0, 1.0) : 0.0;
    return Transform.translate(
      offset: Offset(0, bob),
      child: Transform.rotate(
        angle: lean,
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          '$folder/$_frame.png',
          height: height,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
