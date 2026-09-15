import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/run_play.dart';
import 'exercise_figure.dart';
import 'run_scene.dart';

/// The illustrated companion: one drawing per pose in assets/companion,
/// two of them swapped for a stride, the whole body bobbing and leaning a
/// little with the pace, and the chosen accessory laid over the hair. Which
/// drawing shows follows the same state the stick figure uses (view,
/// resting, expression).
class CompanionSprite extends StatelessWidget {
  const CompanionSprite({
    super.key,
    required this.view,
    required this.resting,
    required this.face,
    required this.phase,
    required this.speed,
    required this.height,
    this.hat = 'none',
    this.hopping = false,
  });

  /// Mid-jump (a kilometre mark or a landmark): the knee-up drawing.
  final bool hopping;

  final SceneView view;
  final bool resting;
  final FigureFace face;

  /// Stride phase in cycles; a new frame every half cycle.
  final double phase;
  final double speed;
  final double height;

  /// One of the ids in [girlHatUnlocks], or 'none'.
  final String hat;

  static const folder = 'assets/companion';

  /// Every file the companion can show, for the worker to keep on the device.
  static const files = [
    'run_side_a', 'run_side_b', 'run_side_c', 'run_side_d', 'sit_side', 'run_side_tired', 'run_side_closed',
    'run_back_a', 'run_back_b', 'stand_back', 'stand_front',
    'hat_cap', 'hat_beanie', 'hat_flower', 'hat_headphones', 'hat_ribbon', 'hat_glasses',
    'face_normal', 'face_smile', 'face_wink', 'face_surprised', 'face_angry', 'face_sad', 'face_shy', 'face_tired',
  ];

  /// The stride from the side is the matched pair of drawings (push-off with
  /// the heel up, then the planted step) swapped every half cycle; mixing in
  /// the other pair, drawn with different arms and hair, made the run jerk.
  /// The knee-up drawing is kept for jumps. From behind the two drawings
  /// already alternate legs.
  String get _frame {
    if (view == SceneView.ahead) {
      if (resting) return 'stand_back';
      return (phase * 2).floor().isOdd ? 'run_back_b' : 'run_back_a';
    }
    if (resting) return 'sit_side';
    if (hopping) return 'run_side_a';
    return (phase * 2).floor().isOdd ? 'run_side_d' : 'run_side_c';
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
        child: DressedPose(frame: _frame, height: height, hat: hat, back: view == SceneView.ahead),
      ),
    );
  }
}

/// One pose drawing with an accessory placed on the hair.
class DressedPose extends StatelessWidget {
  const DressedPose({super.key, required this.frame, required this.height, this.hat = 'none', this.back = false});

  final String frame;
  final double height;
  final String hat;

  /// Seen from behind: a ribbon sits in the middle of the hair.
  final bool back;

  @override
  Widget build(BuildContext context) {
    final aspect = poseAspect[frame] ?? 0.75;
    final width = height * aspect;
    final anchor = hatAnchors[frame];
    final h = height;
    final children = <Widget>[
      Image.asset('${CompanionSprite.folder}/$frame.png', height: height, gaplessPlayback: true, filterQuality: FilterQuality.medium),
    ];
    if (hat != 'none' && anchor != null) {
      final ax = anchor.$1 * width;
      final ay = anchor.$2 * height;
      // Sizes are fractions of the figure's height; the head is about a
      // fifth of it.
      final (double w, double cx, double top) = switch (hat) {
        'cap' => (h * 0.21, ax + h * 0.015, ay - h * 0.03),
        'beanie' => (h * 0.17, ax + h * 0.005, ay - h * 0.045),
        'flower' => (h * 0.21, ax + h * 0.005, ay + h * 0.01),
        'headphones' => (h * 0.19, ax + h * 0.005, ay + h * 0.015),
        'ribbon' => (h * 0.085, back ? ax : ax - h * 0.06, ay + h * 0.045),
        'glasses' => (h * 0.14, ax + h * 0.03, ay + h * 0.085),
        _ => (0.0, 0.0, 0.0),
      };
      if (w > 0) {
        children.add(Positioned(
          left: cx - w / 2,
          top: top,
          child: Image.asset('${CompanionSprite.folder}/hat_$hat.png', width: w, gaplessPlayback: true, filterQuality: FilterQuality.medium),
        ));
      }
    }
    return SizedBox(
      width: width,
      height: height,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}

/// The companion's face in a round sticker frame.
class CompanionFace extends StatelessWidget {
  const CompanionFace({super.key, this.expression = 'smile', this.size = 44, required this.border, required this.background});

  final String expression;
  final double size;
  final Color border;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle, border: Border.all(color: border, width: 1.6)),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        maxWidth: size * 1.3,
        maxHeight: size * 1.6,
        alignment: const Alignment(0, -0.6),
        child: Image.asset('${CompanionSprite.folder}/face_$expression.png', width: size * 1.3, fit: BoxFit.contain),
      ),
    );
  }
}
