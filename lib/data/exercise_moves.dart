import 'package:flutter/material.dart';

import '../widgets/exercise_figure.dart';

// Base bodies. Every entry below is one of these with a different arm or leg.

/// Upright, arms hanging.
const _stand = Pose(
  head: Offset(53, 16),
  neck: Offset(51, 33),
  hip: Offset(50, 57),
  elbow: Offset(52, 46),
  hand: Offset(53, 58),
  knee: Offset(51, 74),
  ankle: Offset(49, 90),
  headR: 7.5,
);

/// On a flat bench, legs off the near end.
const _bench = Pose(
  head: Offset(84, 52),
  neck: Offset(68, 57),
  hip: Offset(38, 57),
  elbow: Offset(76, 44),
  hand: Offset(66, 43),
  knee: Offset(26, 70),
  ankle: Offset(30, 88),
  headR: 7.5,
);

/// Sitting, thighs forward.
const _seat = Pose(
  head: Offset(48, 25),
  neck: Offset(46, 41),
  hip: Offset(40, 63),
  elbow: Offset(56, 50),
  hand: Offset(64, 52),
  knee: Offset(66, 64),
  ankle: Offset(70, 86),
  headR: 7.5,
);

/// Hinged at the hip, flat back.
const _hinge = Pose(
  head: Offset(76, 37),
  neck: Offset(62, 43),
  hip: Offset(38, 53),
  elbow: Offset(62, 58),
  hand: Offset(62, 72),
  knee: Offset(42, 71),
  ankle: Offset(38, 89),
  headR: 7.5,
);

/// Hanging from a bar.
const _hang = Pose(
  head: Offset(52, 32),
  neck: Offset(50, 42),
  hip: Offset(50, 64),
  elbow: Offset(49, 26),
  hand: Offset(48, 11),
  knee: Offset(52, 79),
  ankle: Offset(50, 93),
  headR: 7.5,
);

/// On the floor, face up.
const _floorUp = Pose(
  head: Offset(82, 76),
  neck: Offset(68, 80),
  hip: Offset(38, 80),
  elbow: Offset(74, 70),
  hand: Offset(68, 66),
  knee: Offset(24, 72),
  ankle: Offset(30, 90),
  headR: 7.5,
);

/// On the floor, face down, weight through the arms.
const _floorDown = Pose(
  head: Offset(80, 56),
  neck: Offset(68, 60),
  hip: Offset(44, 70),
  elbow: Offset(72, 74),
  hand: Offset(72, 88),
  knee: Offset(28, 80),
  ankle: Offset(16, 88),
  headR: 7.5,
);

/// Kneeling.
const _kneel = Pose(
  head: Offset(58, 34),
  neck: Offset(54, 48),
  hip: Offset(46, 68),
  elbow: Offset(62, 62),
  hand: Offset(70, 72),
  knee: Offset(38, 84),
  ankle: Offset(22, 88),
  headR: 7.5,
);

const _barOnly = [Gear.barbellHands];
const _dbOnly = [Gear.dumbbells];

/// Poses for the seeded exercises. Keys match the names in the seed data;
/// anything missing falls back to the muscle group icon.
final Map<String, Move> exerciseMoves = {
  // chest
  'Bench press': Move(
    start: _bench.arm(const Offset(76, 44), const Offset(66, 43)),
    end: _bench.arm(const Offset(67, 43), const Offset(66, 27)),
    gear: const [Gear.bench, Gear.barbellHands],
  ),
  'Dumbbell press': Move(
    start: _bench.arm(const Offset(76, 45), const Offset(68, 44)),
    end: _bench.arm(const Offset(68, 43), const Offset(67, 28)),
    gear: const [Gear.bench, Gear.dumbbells],
  ),
  'Incline bench press': Move(
    start: _seat.arm(const Offset(58, 44), const Offset(50, 40)),
    end: _seat.arm(const Offset(50, 32), const Offset(50, 18)),
    gear: const [Gear.bench, Gear.barbellHands],
  ),
  'Chest press': Move(
    start: _seat.arm(const Offset(38, 46), const Offset(48, 46)),
    end: _seat.arm(const Offset(62, 44), const Offset(80, 44)),
    gear: const [Gear.machine],
  ),
  'Pec fly': Move(
    start: _seat.arm(const Offset(34, 40), const Offset(30, 26)),
    end: _seat.arm(const Offset(58, 38), const Offset(76, 40)),
    gear: const [Gear.machine],
  ),
  'Dumbbell fly': Move(
    start: _bench.arm(const Offset(78, 40), const Offset(84, 28)),
    end: _bench.arm(const Offset(70, 42), const Offset(68, 28)),
    gear: const [Gear.bench, Gear.dumbbells],
  ),
  'Cable crossover': Move(
    start: _stand.arm(const Offset(62, 34), const Offset(76, 24)),
    end: _stand.arm(const Offset(58, 46), const Offset(62, 58)),
    gear: const [Gear.cableHigh, Gear.floor],
  ),
  'Push-up': Move(
    start: _floorDown.arm(const Offset(78, 74), const Offset(72, 88)),
    end: _floorDown
        .copyWith(
          head: const Offset(80, 50),
          neck: const Offset(68, 54),
          hip: const Offset(44, 64),
        )
        .arm(const Offset(72, 70), const Offset(72, 88)),
    gear: const [Gear.floor],
  ),

  // back
  'Lat pulldown': Move(
    start: _seat.arm(const Offset(52, 28), const Offset(54, 12)),
    end: _seat.arm(const Offset(60, 44), const Offset(52, 38)),
    gear: const [Gear.cableHigh],
  ),
  'Seated row': Move(
    start: _seat.arm(const Offset(62, 52), const Offset(78, 54)),
    end: _seat.arm(const Offset(38, 52), const Offset(50, 54)),
    gear: const [Gear.cableLow],
  ),
  'Deadlift': Move(
    start: _hinge.arm(const Offset(62, 62), const Offset(62, 80)),
    end: _stand.arm(const Offset(54, 46), const Offset(55, 60)),
    gear: const [Gear.barbellHands, Gear.floor],
  ),
  'Bent-over row': Move(
    start: _hinge.arm(const Offset(62, 60), const Offset(62, 76)),
    end: _hinge.arm(const Offset(68, 44), const Offset(58, 54)),
    gear: _barOnly,
  ),
  'Dumbbell row': Move(
    start: _hinge.arm(const Offset(60, 60), const Offset(60, 76)),
    end: _hinge.arm(const Offset(66, 44), const Offset(56, 54)),
    gear: const [Gear.bench, Gear.dumbbells],
  ),
  'Pull-up': Move(
    start: _hang,
    end: _hang.copyWith(
      head: const Offset(52, 22),
      neck: const Offset(50, 32),
      hip: const Offset(50, 54),
      elbow: const Offset(58, 26),
      hand: const Offset(48, 11),
      knee: const Offset(54, 68),
      ankle: const Offset(48, 82),
    ),
    gear: const [Gear.pullBar],
  ),
  'T-bar row': Move(
    start: _hinge.arm(const Offset(60, 62), const Offset(58, 78)),
    end: _hinge.arm(const Offset(66, 46), const Offset(54, 56)),
    gear: _barOnly,
  ),
  'Face pull': Move(
    start: _stand.arm(const Offset(66, 32), const Offset(80, 26)),
    end: _stand.arm(const Offset(64, 30), const Offset(56, 26)),
    gear: const [Gear.cableHigh, Gear.floor],
  ),

  // shoulders
  'Shoulder press': Move(
    start: _seat.arm(const Offset(54, 40), const Offset(50, 32)),
    end: _seat.arm(const Offset(48, 28), const Offset(48, 14)),
    gear: _barOnly,
  ),
  'Lateral raise': Move(
    start: _stand.arm(const Offset(54, 46), const Offset(56, 60)),
    end: _stand.arm(const Offset(62, 36), const Offset(76, 34)),
    gear: const [Gear.dumbbells, Gear.floor],
  ),
  'Front raise': Move(
    start: _stand.arm(const Offset(54, 46), const Offset(56, 60)),
    end: _stand.arm(const Offset(64, 34), const Offset(78, 33)),
    gear: const [Gear.dumbbells, Gear.floor],
  ),
  'Rear delt fly': Move(
    start: _hinge.arm(const Offset(60, 60), const Offset(60, 76)),
    end: _hinge.arm(const Offset(60, 52), const Offset(44, 44)),
    gear: _dbOnly,
  ),
  'Upright row': Move(
    start: _stand.arm(const Offset(56, 48), const Offset(56, 62)),
    end: _stand.arm(const Offset(64, 40), const Offset(54, 34)),
    gear: const [Gear.barbellHands, Gear.floor],
  ),
  'Arnold press': Move(
    start: _seat.arm(const Offset(56, 44), const Offset(48, 36)),
    end: _seat.arm(const Offset(48, 28), const Offset(48, 14)),
    gear: _dbOnly,
  ),

  // arms
  'Biceps curl': Move(
    start: _stand.arm(const Offset(54, 47), const Offset(55, 61)),
    end: _stand.arm(const Offset(54, 47), const Offset(60, 34)),
    gear: const [Gear.dumbbells, Gear.floor],
  ),
  'Hammer curl': Move(
    start: _stand.arm(const Offset(55, 47), const Offset(57, 61)),
    end: _stand.arm(const Offset(55, 47), const Offset(62, 36)),
    gear: const [Gear.dumbbells, Gear.floor],
  ),
  'Cable curl': Move(
    start: _stand.arm(const Offset(54, 47), const Offset(58, 62)),
    end: _stand.arm(const Offset(54, 47), const Offset(62, 36)),
    gear: const [Gear.cableLow, Gear.floor],
  ),
  'Triceps pushdown': Move(
    start: _stand.arm(const Offset(54, 46), const Offset(62, 38)),
    end: _stand.arm(const Offset(54, 46), const Offset(58, 60)),
    gear: const [Gear.cableHigh, Gear.floor],
  ),
  'Skull crusher': Move(
    start: _bench.arm(const Offset(66, 40), const Offset(78, 44)),
    end: _bench.arm(const Offset(66, 42), const Offset(66, 26)),
    gear: const [Gear.bench, Gear.barbellHands],
  ),
  'Triceps kickback': Move(
    start: _hinge.arm(const Offset(56, 52), const Offset(62, 64)),
    end: _hinge.arm(const Offset(56, 52), const Offset(40, 56)),
    gear: _dbOnly,
  ),
  'Dips': Move(
    start: _hang
        .copyWith(
          head: const Offset(54, 34),
          neck: const Offset(52, 46),
          hip: const Offset(50, 66),
          knee: const Offset(62, 76),
          ankle: const Offset(70, 90),
        )
        .arm(const Offset(40, 46), const Offset(44, 58)),
    end: _hang
        .copyWith(
          head: const Offset(54, 24),
          neck: const Offset(52, 36),
          hip: const Offset(50, 56),
          knee: const Offset(62, 66),
          ankle: const Offset(70, 80),
        )
        .arm(const Offset(44, 46), const Offset(44, 58)),
    gear: const [Gear.pullBar],
  ),

  // legs
  'Squat': Move(
    start: _stand.arm(const Offset(40, 44), const Offset(44, 35)),
    end: _stand
        .copyWith(
          head: const Offset(45, 29),
          neck: const Offset(45, 46),
          hip: const Offset(34, 64),
          knee: const Offset(60, 70),
          ankle: const Offset(49, 89),
        )
        .arm(const Offset(34, 55), const Offset(38, 47)),
    gear: const [Gear.floor, Gear.barbellShoulders],
  ),
  'Leg press': Move(
    start: _seat
        .copyWith(knee: const Offset(52, 44), ankle: const Offset(34, 40))
        .arm(const Offset(48, 54), const Offset(54, 62)),
    end: _seat
        .copyWith(knee: const Offset(30, 52), ankle: const Offset(14, 46))
        .arm(const Offset(48, 54), const Offset(54, 62)),
    gear: const [Gear.machine],
  ),
  'Leg extension': Move(
    start: _seat.leg(const Offset(66, 64), const Offset(70, 86)),
    end: _seat.leg(const Offset(66, 64), const Offset(90, 62)),
    gear: const [Gear.machine],
  ),
  'Leg curl': Move(
    start: _seat.leg(const Offset(68, 62), const Offset(88, 60)),
    end: _seat.leg(const Offset(68, 62), const Offset(72, 84)),
    gear: const [Gear.machine],
  ),
  'Bulgarian split squat': Move(
    start: _stand.leg(const Offset(46, 74), const Offset(44, 90)),
    end: _stand
        .copyWith(
          head: const Offset(50, 24),
          neck: const Offset(48, 40),
          hip: const Offset(44, 62),
        )
        .leg(const Offset(52, 76), const Offset(44, 90)),
    gear: const [Gear.bench, Gear.floor],
  ),
  'Lunge': Move(
    start: _stand.leg(const Offset(51, 74), const Offset(49, 90)),
    end: _stand
        .copyWith(
          head: const Offset(50, 26),
          neck: const Offset(48, 42),
          hip: const Offset(44, 64),
        )
        .leg(const Offset(66, 74), const Offset(70, 90)),
    gear: const [Gear.floor],
  ),
  'Romanian deadlift': Move(
    start: _stand.arm(const Offset(54, 46), const Offset(55, 62)),
    end: _hinge.arm(const Offset(60, 60), const Offset(60, 74)),
    gear: const [Gear.barbellHands, Gear.floor],
  ),
  'Calf raise': Move(
    start: _stand,
    end: _stand.copyWith(
      head: const Offset(53, 10),
      neck: const Offset(51, 27),
      hip: const Offset(50, 51),
      knee: const Offset(51, 68),
      ankle: const Offset(49, 84),
    ),
    gear: const [Gear.floor],
  ),

  // glutes
  'Hip thrust': Move(
    start: _floorUp
        .copyWith(
          head: const Offset(84, 56),
          neck: const Offset(70, 60),
          hip: const Offset(42, 80),
          knee: const Offset(26, 68),
          ankle: const Offset(24, 90),
        )
        .arm(const Offset(76, 62), const Offset(72, 70)),
    end: _floorUp
        .copyWith(
          head: const Offset(84, 56),
          neck: const Offset(70, 60),
          hip: const Offset(44, 64),
          knee: const Offset(26, 68),
          ankle: const Offset(24, 90),
        )
        .arm(const Offset(76, 60), const Offset(72, 64)),
    gear: const [Gear.bench, Gear.barbellHip, Gear.floor],
  ),
  'Hip abduction': Move(
    start: _seat.leg(const Offset(64, 64), const Offset(68, 86)),
    end: _seat.leg(const Offset(72, 66), const Offset(84, 86)),
    gear: const [Gear.machine],
  ),
  'Hip adduction': Move(
    start: _seat.leg(const Offset(72, 66), const Offset(84, 86)),
    end: _seat.leg(const Offset(64, 64), const Offset(68, 86)),
    gear: const [Gear.machine],
  ),
  'Cable kickback': Move(
    start: _stand.leg(const Offset(51, 74), const Offset(49, 90)),
    end: _stand.leg(const Offset(38, 72), const Offset(22, 80)),
    gear: const [Gear.cableLow, Gear.floor],
  ),
  'Glute bridge': Move(
    start: _floorUp.copyWith(hip: const Offset(40, 82), knee: const Offset(24, 74)),
    end: _floorUp.copyWith(hip: const Offset(42, 66), knee: const Offset(24, 74)),
    gear: const [Gear.floor],
  ),

  // core
  'Plank': Move(
    start: _floorDown.arm(const Offset(72, 76), const Offset(78, 88)),
    end: _floorDown
        .copyWith(hip: const Offset(44, 68))
        .arm(const Offset(72, 76), const Offset(78, 88)),
    gear: const [Gear.floor],
  ),
  'Crunch': Move(
    start: _floorUp.arm(const Offset(76, 72), const Offset(82, 66)),
    end: _floorUp
        .copyWith(head: const Offset(74, 62), neck: const Offset(62, 70))
        .arm(const Offset(68, 62), const Offset(72, 58)),
    gear: const [Gear.floor],
  ),
  'Leg raise': Move(
    start: _floorUp.leg(const Offset(22, 80), const Offset(10, 82)),
    end: _floorUp.leg(const Offset(26, 62), const Offset(20, 44)),
    gear: const [Gear.floor],
  ),
  'Ab wheel rollout': Move(
    start: _kneel.arm(const Offset(58, 62), const Offset(64, 74)),
    end: _kneel
        .copyWith(head: const Offset(66, 50), neck: const Offset(56, 58))
        .arm(const Offset(70, 68), const Offset(86, 80)),
    gear: const [Gear.floor],
  ),
  'Hanging leg raise': Move(
    start: _hang,
    end: _hang.leg(const Offset(64, 58), const Offset(78, 46)),
    gear: const [Gear.pullBar],
  ),
  'Russian twist': Move(
    start: _floorUp
        .copyWith(
          head: const Offset(60, 46),
          neck: const Offset(54, 58),
          hip: const Offset(38, 80),
          knee: const Offset(22, 70),
          ankle: const Offset(20, 88),
        )
        .arm(const Offset(58, 66), const Offset(70, 64)),
    end: _floorUp
        .copyWith(
          head: const Offset(60, 46),
          neck: const Offset(54, 58),
          hip: const Offset(38, 80),
          knee: const Offset(22, 70),
          ankle: const Offset(20, 88),
        )
        .arm(const Offset(50, 68), const Offset(44, 58)),
    gear: const [Gear.floor],
  ),
};

Move? moveFor(String name) => exerciseMoves[name];
