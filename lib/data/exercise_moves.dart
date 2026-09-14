import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../widgets/exercise_figure.dart';

// Angles are degrees from straight down; positive swings forward. The torso
// angle is from upright, positive leaning forward, 90 lying head-forward.
// Limb lengths are fixed in the figure, so these can only describe positions
// a body can reach. Feet rest at about y=90; the floor is drawn at 94.

/// Upright, arms hanging, feet on the floor.
const _stand = Pose(hip: Offset(50, 55));

/// Sitting, thighs forward, feet down.
const _seat = Pose(hip: Offset(40, 64), leg: Limb(80, 10));

/// Flat on a bench, head to the front, feet on the floor.
const _lie = Pose(hip: Offset(34, 62), torso: 90, leg: Limb(-55, 0));

/// Hinged at the hip, knees soft.
const _hinge = Pose(hip: Offset(44, 56), torso: 70, leg: Limb(-15, 10));

/// Hanging with the knees tucked back.
const _hang = Pose(hip: Offset(50, 66), arm: Limb(180, 180), leg: Limb(-10, -70));

/// On the floor face up, knees bent, feet flat.
const _floorUp = Pose(hip: Offset(36, 84), torso: 90, arm: Limb(-80, -80), leg: Limb(-120, -15));

/// Movements for the seeded exercises. Keys match the seed data.
final Map<String, Move> exerciseMoves = {
  // chest
  'Bench press': Move(
    start: _lie.copyWith(arm: const Limb(-120, 125)),
    end: _lie.copyWith(arm: const Limb(-180, 180)),
    gear: const [Gear.bench, Gear.barbell, Gear.floor],
  ),
  'Dumbbell press': Move(
    start: _lie.copyWith(arm: const Limb(-120, 125)),
    end: _lie.copyWith(arm: const Limb(-180, 180)),
    gear: const [Gear.bench, Gear.dumbbell, Gear.floor],
  ),
  'Incline bench press': Move(
    start: const Pose(hip: Offset(40, 68), torso: -40, arm: Limb(60, 150), leg: Limb(80, 0)),
    end: const Pose(hip: Offset(40, 68), torso: -40, arm: Limb(130, 130), leg: Limb(80, 0)),
    gear: const [Gear.bench, Gear.seat, Gear.barbell, Gear.floor],
  ),
  'Chest press': Move(
    start: _seat.copyWith(arm: const Limb(30, 100)),
    end: _seat.copyWith(arm: const Limb(90, 90)),
    gear: const [Gear.seat, Gear.padHand],
  ),
  'Pec fly': Move(
    start: const Pose(hip: Offset(50, 58), arm: Limb(90, 90), leg: Limb(8, 8)),
    end: const Pose(hip: Offset(50, 58), arm: Limb(51, -38), leg: Limb(8, 8)),
    gear: const [Gear.seat, Gear.padHand],
    view: Facing.front,
  ),
  'Dumbbell fly': Move(
    start: const Pose(hip: Offset(50, 58), arm: Limb(95, 80), leg: Limb(8, 8)),
    end: const Pose(hip: Offset(50, 58), arm: Limb(160, 200), leg: Limb(8, 8)),
    gear: const [Gear.dumbbell, Gear.floor],
    view: Facing.front,
  ),
  'Cable crossover': Move(
    start: const Pose(hip: Offset(50, 58), arm: Limb(135, 135), leg: Limb(8, 8)),
    end: const Pose(hip: Offset(50, 58), arm: Limb(30, -30), leg: Limb(8, 8)),
    gear: const [Gear.cableHigh, Gear.floor],
    view: Facing.front,
  ),
  'Push-up': Move(
    start: const Pose(hip: Offset(38, 72), torso: 70, arm: Limb(30, 0), leg: Limb(-66, -60)),
    end: const Pose(hip: Offset(38, 78), torso: 70, arm: Limb(48, -18), leg: Limb(-70, -69)),
    gear: const [Gear.floor],
  ),

  // back
  'Lat pulldown': Move(
    start: _seat.copyWith(arm: const Limb(170, 170)),
    end: _seat.copyWith(arm: const Limb(-20, 100)),
    gear: const [Gear.seat, Gear.padKnee, Gear.cableHigh],
  ),
  'Seated row': Move(
    start: const Pose(hip: Offset(36, 66), arm: Limb(90, 90), leg: Limb(80, 60)),
    end: const Pose(hip: Offset(36, 66), torso: -10, arm: Limb(-30, 60), leg: Limb(80, 60)),
    gear: const [Gear.seat, Gear.plateFeet, Gear.cableFront],
  ),
  'Deadlift': Move(
    start: const Pose(hip: Offset(44, 62), torso: 70, leg: Limb(-40, 40)),
    end: _stand,
    gear: const [Gear.barbell, Gear.floor],
  ),
  'Bent-over row': Move(
    start: _hinge,
    end: _hinge.copyWith(arm: const Limb(-60, -20)),
    gear: const [Gear.barbell, Gear.floor],
  ),
  'Dumbbell row': Move(
    start: _hinge.copyWith(arm2: const Limb(40, 20)),
    end: _hinge.copyWith(arm: const Limb(-60, -20), arm2: const Limb(40, 20)),
    gear: const [Gear.benchHand2, Gear.dumbbellUpright, Gear.floor],
  ),
  'Pull-up': Move(
    start: _hang,
    end: _hang.copyWith(hip: const Offset(50, 52), arm: const Limb(118, 243)),
    gear: const [Gear.pullBar],
  ),
  'T-bar row': Move(
    start: _hinge.copyWith(torso: 55, arm: const Limb(10, 10)),
    end: _hinge.copyWith(torso: 55, arm: const Limb(-50, -10)),
    gear: const [Gear.barbell, Gear.floor],
  ),
  'Face pull': Move(
    start: _stand.copyWith(arm: const Limb(110, 110)),
    end: _stand.copyWith(arm: const Limb(100, 245)),
    gear: const [Gear.cableHigh, Gear.floor],
  ),

  // shoulders
  'Shoulder press': Move(
    start: _seat.copyWith(arm: const Limb(-20, 160)),
    end: _seat.copyWith(arm: const Limb(180, 180)),
    gear: const [Gear.seat, Gear.barbell],
  ),
  'Lateral raise': Move(
    start: const Pose(hip: Offset(50, 58), arm: Limb(5, 5), leg: Limb(8, 8)),
    end: const Pose(hip: Offset(50, 58), arm: Limb(85, 85), leg: Limb(8, 8)),
    gear: const [Gear.dumbbell, Gear.floor],
    view: Facing.front,
  ),
  'Front raise': Move(
    start: _stand,
    end: _stand.copyWith(arm: const Limb(85, 85)),
    gear: const [Gear.dumbbell, Gear.floor],
  ),
  'Rear delt fly': Move(
    start: _hinge,
    end: _hinge.copyWith(arm: const Limb(-70, -70)),
    gear: const [Gear.dumbbell, Gear.floor],
  ),
  'Upright row': Move(
    start: _stand,
    end: _stand.copyWith(arm: const Limb(60, -122)),
    gear: const [Gear.barbell, Gear.floor],
  ),
  'Arnold press': Move(
    start: _seat.copyWith(arm: const Limb(40, 150)),
    end: _seat.copyWith(arm: const Limb(180, 180)),
    gear: const [Gear.seat, Gear.dumbbell],
  ),

  // arms
  'Biceps curl': Move(
    start: _stand,
    end: _stand.copyWith(arm: const Limb(10, 150)),
    gear: const [Gear.dumbbell, Gear.floor],
  ),
  'Hammer curl': Move(
    start: _stand,
    end: _stand.copyWith(arm: const Limb(10, 150)),
    gear: const [Gear.dumbbellUpright, Gear.floor],
  ),
  'Cable curl': Move(
    start: _stand,
    end: _stand.copyWith(arm: const Limb(10, 150)),
    gear: const [Gear.cableLow, Gear.floor],
  ),
  'Triceps pushdown': Move(
    start: _stand.copyWith(arm: const Limb(0, 150)),
    end: _stand.copyWith(arm: const Limb(0, 20)),
    gear: const [Gear.cableHigh, Gear.floor],
  ),
  'Skull crusher': Move(
    start: _lie.copyWith(arm: const Limb(-180, -180)),
    end: _lie.copyWith(arm: const Limb(-180, -260)),
    gear: const [Gear.bench, Gear.barbell, Gear.floor],
  ),
  'Triceps kickback': Move(
    start: _hinge.copyWith(arm: const Limb(-70, 0)),
    end: _hinge.copyWith(arm: const Limb(-70, -70)),
    gear: const [Gear.dumbbellUpright, Gear.floor],
  ),
  'Dips': Move(
    start: const Pose(hip: Offset(50, 60), leg: Limb(-10, -70)),
    end: const Pose(hip: Offset(50, 72), arm: Limb(-70, 52), leg: Limb(-10, -70)),
    gear: const [Gear.dipBars],
  ),

  // legs
  'Squat': Move(
    start: _stand.copyWith(arm: const Limb(-40, 130)),
    end: const Pose(hip: Offset(44, 70), torso: 25, arm: Limb(-40, 130), leg: Limb(80, -35)),
    gear: const [Gear.barbellShoulders, Gear.floor],
  ),
  'Leg press': Move(
    start: const Pose(hip: Offset(42, 70), torso: -45, arm: Limb(20, 60), leg: Limb(110, 60)),
    end: const Pose(hip: Offset(42, 70), torso: -45, arm: Limb(20, 60), leg: Limb(130, 130)),
    gear: const [Gear.seat, Gear.bench, Gear.plateFeet],
  ),
  'Leg extension': Move(
    start: _seat.copyWith(arm: const Limb(20, 60)),
    end: _seat.copyWith(arm: const Limb(20, 60), leg: const Limb(85, 85)),
    gear: const [Gear.seat, Gear.padAnkle, Gear.frame],
  ),
  'Leg curl': Move(
    start: _seat.copyWith(arm: const Limb(20, 60), leg: const Limb(85, 85)),
    end: _seat.copyWith(arm: const Limb(20, 60), leg: const Limb(85, -30)),
    gear: const [Gear.seat, Gear.padAnkle, Gear.frame],
  ),
  'Bulgarian split squat': Move(
    start: const Pose(hip: Offset(48, 55), torso: 10, leg2: Limb(-40, -115)),
    end: const Pose(hip: Offset(48, 66), torso: 15, leg: Limb(60, -40), leg2: Limb(-56, -139)),
    gear: const [Gear.benchFoot2, Gear.floor],
  ),
  'Lunge': Move(
    start: _stand.copyWith(leg2: const Limb(0, 0)),
    end: const Pose(hip: Offset(46, 66), torso: 5, leg: Limb(70, -20), leg2: Limb(-45, -50)),
    gear: const [Gear.floor],
  ),
  'Romanian deadlift': Move(
    start: _stand,
    end: const Pose(hip: Offset(46, 58), torso: 65, leg: Limb(-10, 0)),
    gear: const [Gear.barbell, Gear.floor],
  ),
  'Calf raise': Move(
    start: const Pose(hip: Offset(50, 58)),
    end: const Pose(hip: Offset(50, 46)),
    gear: const [Gear.calfBlock, Gear.foot, Gear.floor],
  ),

  // glutes
  'Hip thrust': Move(
    start: const Pose(hip: Offset(44, 78), torso: 55, arm: Limb(-50, -45), leg: Limb(-100, 20)),
    end: const Pose(hip: Offset(38.6, 61), torso: 90, arm: Limb(-90, -90), leg: Limb(-35, 5)),
    gear: const [Gear.benchShoulders, Gear.barbellHip, Gear.floor],
  ),
  'Hip abduction': Move(
    start: const Pose(hip: Offset(50, 54), arm: Limb(20, 60), leg: Limb(8, 0)),
    end: const Pose(hip: Offset(50, 54), arm: Limb(20, 60), leg: Limb(40, 0)),
    gear: const [Gear.seat, Gear.padKneeOuter],
    view: Facing.front,
  ),
  'Hip adduction': Move(
    start: const Pose(hip: Offset(50, 54), arm: Limb(20, 60), leg: Limb(40, 0)),
    end: const Pose(hip: Offset(50, 54), arm: Limb(20, 60), leg: Limb(12, 0)),
    gear: const [Gear.seat, Gear.padKneeInner],
    view: Facing.front,
  ),
  'Cable kickback': Move(
    start: const Pose(hip: Offset(52, 55), torso: 15, arm: Limb(60, 30), leg: Limb(5, 0), leg2: Limb(0, 0)),
    end: const Pose(hip: Offset(52, 55), torso: 15, arm: Limb(60, 30), leg: Limb(-40, -40), leg2: Limb(0, 0)),
    gear: const [Gear.post, Gear.cableAnkle, Gear.floor],
  ),
  'Glute bridge': Move(
    start: _floorUp,
    end: const Pose(hip: Offset(38, 73), torso: 111, arm: Limb(-80, -80), leg: Limb(-77, -18)),
    gear: const [Gear.floor],
  ),

  // core
  'Plank': Move(
    start: const Pose(hip: Offset(40, 80), torso: 75, arm: Limb(0, 90), leg: Limb(-75, -80)),
    end: const Pose(hip: Offset(40, 77), torso: 75, arm: Limb(0, 90), leg: Limb(-75, -80)),
    gear: const [Gear.floor],
  ),
  'Crunch': Move(
    start: _floorUp.copyWith(arm: const Limb(150, 45)),
    end: _floorUp.copyWith(torso: 70, arm: const Limb(150, 45)),
    gear: const [Gear.floor],
  ),
  'Leg raise': Move(
    start: const Pose(hip: Offset(44, 84), torso: 90, arm: Limb(-80, -80), leg: Limb(-90, -90)),
    end: const Pose(hip: Offset(44, 84), torso: 90, arm: Limb(-80, -80), leg: Limb(-170, -170)),
    gear: const [Gear.floor],
  ),
  'Ab wheel rollout': Move(
    start: const Pose(hip: Offset(44, 66), torso: 60, leg: Limb(0, -90)),
    end: const Pose(hip: Offset(34, 70), torso: 80, arm: Limb(50, 50), leg: Limb(35, -90)),
    gear: const [Gear.wheel, Gear.floor],
  ),
  'Hanging leg raise': Move(
    start: _hang,
    end: _hang.copyWith(leg: const Limb(-150, -90)),
    gear: const [Gear.pullBar],
  ),
  'Russian twist': Move(
    start: const Pose(hip: Offset(50, 64), arm: Limb(55, 47), arm2: Limb(-27, -84), leg: Limb(25, -60)),
    end: const Pose(hip: Offset(50, 64), arm: Limb(-27, -84), arm2: Limb(55, 47), leg: Limb(25, -60)),
    gear: const [Gear.floor],
    view: Facing.front,
  ),
};

/// Movements for the cardio types. Strides alternate the two sides.
final Map<CardioType, Move> cardioMoves = {
  CardioType.running: Move(
    start: const Pose(hip: Offset(50, 56), torso: 12, arm: Limb(-40, 50), arm2: Limb(40, 130), leg: Limb(45, 20), leg2: Limb(-30, -75)),
    end: const Pose(hip: Offset(50, 56), torso: 12, arm: Limb(40, 130), arm2: Limb(-40, 50), leg: Limb(-30, -75), leg2: Limb(45, 20)),
    gear: const [Gear.floor],
  ),
  CardioType.walking: Move(
    start: const Pose(hip: Offset(50, 55), torso: 3, arm: Limb(-25, -25), arm2: Limb(25, 25), leg: Limb(25, 15), leg2: Limb(-25, -15)),
    end: const Pose(hip: Offset(50, 55), torso: 3, arm: Limb(25, 25), arm2: Limb(-25, -25), leg: Limb(-25, -15), leg2: Limb(25, 15)),
    gear: const [Gear.floor],
  ),
  CardioType.cycling: Move(
    start: const Pose(hip: Offset(42, 52), torso: 35, arm: Limb(70, 30), leg: Limb(60, -10), leg2: Limb(10, 20)),
    end: const Pose(hip: Offset(42, 52), torso: 35, arm: Limb(70, 30), leg: Limb(10, 20), leg2: Limb(60, -10)),
    gear: const [Gear.bike, Gear.floor],
  ),
  CardioType.elliptical: Move(
    start: const Pose(hip: Offset(48, 55), torso: 5, arm: Limb(60, 60), arm2: Limb(30, 30), leg: Limb(25, 5), leg2: Limb(-25, -5)),
    end: const Pose(hip: Offset(48, 55), torso: 5, arm: Limb(30, 30), arm2: Limb(60, 60), leg: Limb(-25, -5), leg2: Limb(25, 5)),
    gear: const [Gear.pedals, Gear.post, Gear.floor],
  ),
  CardioType.stairs: Move(
    start: const Pose(hip: Offset(48, 56), torso: 10, arm: Limb(40, 20), arm2: Limb(40, 20), leg: Limb(70, -20), leg2: Limb(-5, 0)),
    end: const Pose(hip: Offset(48, 50), torso: 10, arm: Limb(40, 20), arm2: Limb(40, 20), leg: Limb(40, 10), leg2: Limb(-20, -40)),
    gear: const [Gear.step, Gear.post, Gear.floor],
  ),
  CardioType.rowing: Move(
    start: const Pose(hip: Offset(40, 66), torso: 15, arm: Limb(90, 90), leg: Limb(90, 20)),
    end: const Pose(hip: Offset(34, 66), torso: -15, arm: Limb(-40, 40), leg: Limb(80, 70)),
    gear: const [Gear.seat, Gear.plateFeet, Gear.cableFront],
  ),
  CardioType.swimming: Move(
    start: const Pose(hip: Offset(38, 58), torso: 90, arm: Limb(135, 60), arm2: Limb(-30, -100), leg: Limb(-85, -95), leg2: Limb(-95, -85)),
    end: const Pose(hip: Offset(38, 58), torso: 90, arm: Limb(-30, -100), arm2: Limb(135, 60), leg: Limb(-95, -85), leg2: Limb(-85, -95)),
    gear: const [Gear.water],
  ),
  CardioType.hiit: Move(
    start: const Pose(hip: Offset(46, 70), torso: 30, arm: Limb(-40, -40), leg: Limb(80, -35)),
    end: const Pose(hip: Offset(50, 48), arm: Limb(110, 110), leg: Limb(10, -10)),
    gear: const [Gear.floor],
  ),
  CardioType.yoga: Move(
    start: const Pose(hip: Offset(50, 55), arm: Limb(20, 160)),
    end: const Pose(hip: Offset(48, 56), torso: 100),
    gear: const [Gear.floor],
  ),
  CardioType.other: Move(
    start: const Pose(hip: Offset(50, 58), arm: Limb(8, 8), leg: Limb(4, 0)),
    end: const Pose(hip: Offset(50, 58), arm: Limb(150, 150), leg: Limb(25, 0)),
    gear: const [Gear.floor],
    view: Facing.front,
  ),
};

Move? moveFor(String name) => exerciseMoves[name];
