import 'package:flutter/material.dart';

import '../widgets/exercise_figure.dart';

/// Movements drawn for the exercise list. Names match the seed data; anything
/// missing simply falls back to the muscle group icon.
const _benchDown = Pose(
  head: Offset(84, 52),
  neck: Offset(68, 57),
  hip: Offset(38, 57),
  elbow: Offset(76, 44),
  hand: Offset(66, 43),
  knee: Offset(26, 70),
  ankle: Offset(30, 88),
  headR: 7.5,
);

const _benchUp = Pose(
  head: Offset(84, 52),
  neck: Offset(68, 57),
  hip: Offset(38, 57),
  elbow: Offset(67, 43),
  hand: Offset(66, 27),
  knee: Offset(26, 70),
  ankle: Offset(30, 88),
  headR: 7.5,
);

const _squatUp = Pose(
  head: Offset(53, 16),
  neck: Offset(51, 35),
  hip: Offset(50, 55),
  elbow: Offset(40, 42),
  hand: Offset(44, 33),
  knee: Offset(53, 72),
  ankle: Offset(49, 89),
  headR: 7.5,
);

const _squatDown = Pose(
  head: Offset(45, 29),
  neck: Offset(45, 46),
  hip: Offset(34, 64),
  elbow: Offset(34, 53),
  hand: Offset(38, 45),
  knee: Offset(60, 70),
  ankle: Offset(49, 89),
  headR: 7.5,
);

const Map<String, Move> exerciseMoves = {
  'Bench press': Move(
    start: _benchDown,
    end: _benchUp,
    gear: [Gear.bench, Gear.barbellHands],
  ),
  'Squat': Move(
    start: _squatUp,
    end: _squatDown,
    gear: [Gear.floor, Gear.barbellShoulders],
  ),
};

Move? moveFor(String name) => exerciseMoves[name];
