import 'dart:math' as math;

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
  // Toes on a step, heel dropping below it and rising well above; the foot
  // pivots about the toes, so the body rises exactly as much as the heel.
  'Calf raise': Move(
    start: const Pose(hip: Offset(44.4, 54.6), arm: Limb(70, 40), foot: -15),
    end: const Pose(hip: Offset(45, 46.6), arm: Limb(70, 40), foot: 24),
    gear: const [Gear.calfBlock, Gear.rail, Gear.floor],
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
    start: _floorUp.copyWith(arm: const Limb(180, 55)),
    end: _floorUp.copyWith(torso: 70, arm: const Limb(180, 55)),
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
  // Hands together sweep across at chest height; the middle frame keeps them
  // up instead of letting the swing dip through the lap.
  'Russian twist': const Move.frames(
    [
      Pose(hip: Offset(50, 64), arm: Limb(55, 47), arm2: Limb(-27, -84), leg: Limb(25, -60)),
      Pose(hip: Offset(50, 64), arm: Limb(59, -77), arm2: Limb(-59, 77), leg: Limb(25, -60)),
      Pose(hip: Offset(50, 64), arm: Limb(-27, -84), arm2: Limb(55, 47), leg: Limb(25, -60)),
    ],
    gear: [Gear.floor],
    view: Facing.front,
  ),
};

// Cardio. Gait and strokes are cycles: each is a function of phase, sampled
// as the loop plays forward, so a stride never runs backwards.

/// Leg angles that put the foot at [foot], knee bent to the front (or up).
Limb _legTo(Offset hip, Offset foot, {bool kneeUp = false}) {
  final v = foot - hip;
  final d = v.distance.clamp(thighLen - shinLen + 0.5, thighLen + shinLen - 0.5);
  final u = v / v.distance;
  final cosA = (thighLen * thighLen + d * d - shinLen * shinLen) / (2 * thighLen * d);
  final a = math.acos(cosA.clamp(-1.0, 1.0));
  Offset rot(double r) => Offset(
        u.dx * math.cos(r) - u.dy * math.sin(r),
        u.dx * math.sin(r) + u.dy * math.cos(r),
      );
  final k1 = hip + rot(a) * thighLen;
  final k2 = hip + rot(-a) * thighLen;
  final knee = kneeUp ? (k1.dy < k2.dy ? k1 : k2) : (k1.dx > k2.dx ? k1 : k2);
  final ankle = knee + (foot - knee) / (foot - knee).distance * shinLen;
  return Limb(angleOf(knee - hip), angleOf(ankle - knee));
}

double _sin(double x) => math.sin(x);
double _cos(double x) => math.cos(x);

/// A smooth periodic bump of unit height at [x] = 0, narrower for a larger
/// [k]; it has no corners anywhere, so a cycle built from it never jerks.
double _bump(double x, double k) => math.exp(k * (_cos(x) - 1));

/// Running: the thigh swings, the knee bends most just after the foot leaves
/// the ground (the heel kicks up behind), stays a little bent as the knee
/// drives forward and the foot lands, gives through the stance and is
/// straight again at the push-off. The arms pump against the legs.
Pose _run(double p) {
  Limb leg(double q) {
    final thigh = 10 + 36 * _sin(q);
    final flex = 12 + 100 * _bump(q - 5.7, 3.0) + 28 * _bump(q - 2.9, 4.0) + 22 * _bump(q - 1.4, 6.0);
    return Limb(thigh, thigh - flex);
  }

  Limb arm(double q) {
    final upper = -42 * _sin(q);
    // The elbow opens a little on the back swing and closes in front.
    return Limb(upper, upper + 85 - 15 * _sin(q));
  }

  // Flight: after each push-off, until the other foot lands, the body is
  // in the air. Twice a cycle, centred between the push-off and the next
  // landing.
  final flight = _bump(2 * (p - 1.58), 4.0);
  return Pose(
    hip: Offset(50, 55 - 4 * flight),
    torso: 16 + 2 * _sin(2 * p),
    arm: arm(p),
    arm2: arm(p + math.pi),
    leg: leg(p),
    leg2: leg(p + math.pi),
  );
}

Pose _walk(double p) {
  Limb leg(double q) {
    final thigh = 24 * _sin(q);
    final flex = 5 + 40 * (1 + _cos(q + 0.5)) / 2;
    return Limb(thigh, thigh - flex);
  }

  Limb arm(double q) {
    final upper = -18 * _sin(q);
    return Limb(upper, upper + 8);
  }

  return Pose(
    hip: const Offset(50, 55),
    torso: 3,
    arm: arm(p),
    arm2: arm(p + math.pi),
    leg: leg(p),
    leg2: leg(p + math.pi),
  );
}

/// Feet go round the crank; the knees are found from that.
Pose _cycle(double p) {
  const hip = Offset(40, 50);
  const crank = Offset(46, 76);
  // Clockwise on screen: the pedal moves forward over the top of the crank,
  // the way a bike is ridden with its front wheel to the right.
  Offset foot(double q) => crank + Offset(-8 * _sin(q), 8 * _cos(q));
  return Pose(
    hip: hip,
    torso: 35,
    // Upper arms hang forward from the leaning shoulders, elbows low.
    arm: const Limb(46, 30),
    leg: _legTo(hip, foot(p)),
    leg2: _legTo(hip, foot(p + math.pi)),
  );
}

/// Where a foot is on an endless staircase, in the box, for a phase [t] in
/// cycles: it rides a tread back and down for six tenths of the cycle, then
/// swings up and forward over the next one, leaving and landing at the
/// treads' own speed so nothing jolts. The other foot is half a cycle
/// behind. Treads pass at two a cycle, [climbRun] across and [climbRise] up.
const climbRun = 10.0;
const climbRise = 7.5;
const climbStance = 0.6;
Offset climbFoot(double t) {
  const land = Offset(58, 74);
  const perCycle = Offset(-2 * climbRun, 2 * climbRise);
  final u = t % 1;
  if (u < climbStance) return land + perCycle * u;
  final lift = land + perCycle * climbStance;
  final s = (u - climbStance) / (1 - climbStance);
  // Cubic Hermite from the lift-off to the landing with the tread's
  // velocity at both ends, plus a lift that starts and ends flat.
  final s2 = s * s;
  final s3 = s2 * s;
  final h00 = 2 * s3 - 3 * s2 + 1;
  final h10 = s3 - 2 * s2 + s;
  final h01 = -2 * s3 + 3 * s2;
  final h11 = s3 - s2;
  final m = perCycle * (1 - climbStance);
  final along = lift * h00 + m * h10 + land * h01 + m * h11;
  final l = _sin(math.pi * s);
  return along - Offset(0, 10 * l * l);
}

/// Climbing stairs: the hips stay level over the treads while the feet step
/// up; the arms swing a little.
const climbHip = Offset(50, 37);

/// The stick figure's legs are shorter than the illustration's, so it
/// reaches for the same steps scaled toward the hip.
const _climbReach = 0.88;

Pose _climb(double p) {
  const hip = climbHip;
  final t = p / (2 * math.pi);
  Limb arm(double q) {
    final upper = -14 * _sin(q);
    return Limb(upper, upper + 30);
  }

  return Pose(
    hip: hip,
    torso: 10,
    arm: arm(p),
    arm2: arm(p + math.pi),
    leg: _legTo(hip, hip + (climbFoot(t) - hip) * _climbReach, kneeUp: true),
    leg2: _legTo(hip, hip + (climbFoot(t + 0.5) - hip) * _climbReach, kneeUp: true),
  );
}

/// Feet glide round a flat ellipse while the hands ride the moving handles.
Pose _elliptical(double p) {
  const hip = Offset(48, 55);
  Offset foot(double q) => Offset(50 + 13 * _cos(q), 84 + 4 * _sin(q));
  Limb arm(double q) {
    final upper = 55 + 18 * _sin(q);
    return Limb(upper, upper - 15);
  }

  return Pose(
    hip: hip,
    torso: 6,
    arm: arm(p),
    arm2: arm(p + math.pi),
    leg: _legTo(hip, foot(p)),
    leg2: _legTo(hip, foot(p + math.pi)),
  );
}

/// Catch, drive, finish, recovery. The seat slides, the feet stay on the
/// plate, and the arms pull only once the legs are most of the way.
Pose _row(double p) {
  final hip = Offset(40 + 6 * _cos(p), 66);
  final pull = (1 - _cos(p - 0.7)) / 2;
  return Pose(
    hip: hip,
    torso: 2 + 18 * _cos(p),
    arm: Limb(90 - 125 * pull, 90 - 40 * pull),
    leg: _legTo(hip, const Offset(62, 82), kneeUp: true),
  );
}

/// Limb interpolated round a ring of key positions, [q] in radians.
Limb _ring(List<Limb> keys, double q) {
  final n = keys.length;
  var f = (q / (2 * math.pi)) % 1;
  if (f < 0) f += 1;
  final x = f * n;
  final i = x.floor() % n;
  final a = keys[i];
  final b = keys[(i + 1) % n];
  final t = x - i;
  // Angles turn the short way round, so a key at -150 followed by one at 170
  // swings 40 degrees over the top instead of 320 through the body.
  double turn(double from, double to) {
    var d = (to - from) % 360;
    if (d > 180) d -= 360;
    return from + d * t;
  }

  return Limb(turn(a.upper, b.upper), turn(a.lower, b.lower));
}

/// Freestyle, side on. The arm passes through entry, a high-elbow catch,
/// the push past the hip, a high-elbow recovery and the reach forward; the
/// other arm is half a cycle behind. A small flutter kick.
Pose _swim(double p) {
  const stroke = [
    Limb(90, 80), // entry, arm long at the surface
    Limb(40, -20), // catch: elbow high, forearm down under the chest
    Limb(-70, -60), // push through past the hip
    Limb(-140, -20), // recovery: elbow up behind, hand hanging at the water
    Limb(175, 60), // elbow over the shoulder, hand swinging low and forward
  ];
  Limb leg(double q) {
    final thigh = -92 + 6 * _sin(3 * q);
    return Limb(thigh, thigh + 8 * _sin(3 * q + 1));
  }

  // The body rolls up a little for a breath.
  final breath = swimBreathAmount(p / (2 * math.pi));
  return Pose(
    hip: Offset(34, 58 + 1.2 * _sin(2 * p) - 3 * breath),
    torso: 90,
    arm: _ring(stroke, p),
    arm2: _ring(stroke, p + math.pi),
    leg: leg(p),
    leg2: leg(p + math.pi),
  );
}

/// How far into a breath the swimmer is at [strokes] into the swim, 0 to 1:
/// every other stroke, while the near arm recovers, the face turns to the
/// side and comes up. Smooth at both ends.
double swimBreathAmount(double strokes) {
  final u = (strokes % 2 - 1.5) / 0.55;
  if (u <= 0 || u >= 1) return 0;
  final s = _sin(math.pi * u);
  return s * s;
}

/// Movements for the cardio types.
/// Sitting on the ground, legs out along it and hands behind for support,
/// seen from the side; the two poses are a breath in and out. Used by the run
/// companion when the speed is zero.
const sitMove = Move(
  start: Pose(hip: Offset(46, 91), torso: -8, arm: Limb(-15, -15), leg: Limb(90, 100), arm2: Limb(-15, -15), leg2: Limb(88, 102)),
  end: Pose(hip: Offset(46, 91), torso: -5, arm: Limb(-13, -14), leg: Limb(90, 100), arm2: Limb(-13, -14), leg2: Limb(88, 102)),
);

/// Standing still, seen from behind, breathing.
const standBackMove = Move(
  start: Pose(hip: Offset(50, 59), torso: 0, arm: Limb(14, 10), leg: Limb(4, 0)),
  end: Pose(hip: Offset(50, 58.5), torso: 2, arm: Limb(16, 12), leg: Limb(4, 0)),
  view: Facing.front,
);

/// Seen from behind, a leg swinging forward can only be shown by folding the
/// knee so the foot rises beside the thigh. The fold happens over a short
/// part of the cycle, since a half-folded shin reads as a kick to the side;
/// arms stay bent and pump a little. These cycles keep the form when the
/// scene looks down the road.
double _foldOf(double q) {
  // Straight while the leg is in support (sin below 0.15), folded for the
  // swing; the two legs are half a cycle apart, so one is always straight.
  final f = ((_sin(q) - 0.15) / 0.5).clamp(0.0, 1.0);
  return f * f * (3 - 2 * f);
}

Pose _runBack(double p) {
  Limb leg(double q) {
    final thigh = 5 + 3 * _sin(q);
    return Limb(thigh, thigh + 172 * _foldOf(q));
  }

  Limb arm(double q) {
    final upper = -6 + 4 * _sin(q);
    return Limb(upper, upper + 150 + 12 * _sin(q));
  }

  return Pose(
    hip: Offset(50, 56 + 1.5 * _cos(2 * p)),
    torso: 0,
    arm: arm(p + math.pi),
    arm2: arm(p),
    leg: leg(p),
    leg2: leg(p + math.pi),
  );
}

Pose _walkBack(double p) {
  Limb leg(double q) {
    final thigh = 4 + 2 * _sin(q);
    return Limb(thigh, thigh + 45 * _foldOf(q));
  }

  Limb arm(double q) {
    final upper = -3 + 5 * _sin(q);
    return Limb(upper, upper + 25 + 15 * _sin(q));
  }

  return Pose(
    hip: Offset(50 + 1.2 * _sin(p), 57 + 0.8 * _cos(2 * p)),
    torso: 0,
    arm: arm(p + math.pi),
    arm2: arm(p),
    leg: leg(p),
    leg2: leg(p + math.pi),
  );
}

Pose _cycleBack(double p) {
  Limb leg(double q) => Limb(9, 9 + 168 * _foldOf(q));

  return Pose(
    hip: const Offset(50, 60),
    torso: 0,
    arm: const Limb(24, 18),
    leg: leg(p),
    leg2: leg(p + math.pi),
  );
}

/// A squat from behind: the hips drop, the knees turn out a little.
const _squatBack = Move(
  start: Pose(hip: Offset(50, 59), torso: 0, arm: Limb(14, 10), leg: Limb(4, 0)),
  end: Pose(hip: Offset(50, 69), torso: 0, arm: Limb(34, 40), leg: Limb(45, -45)),
  view: Facing.front,
);

/// The cycle to draw when the scene looks down the road, by activity.
Move backMoveFor(CardioType kind) => switch (kind) {
      CardioType.cycling => const Move.cycle(_cycleBack, view: Facing.front),
      CardioType.walking || CardioType.yoga => const Move.cycle(_walkBack, view: Facing.front),
      CardioType.hiit || CardioType.other => _squatBack,
      _ => const Move.cycle(_runBack, view: Facing.front),
    };

final Map<CardioType, Move> cardioMoves = {
  CardioType.running: const Move.cycle(_run, gear: [Gear.floor]),
  CardioType.walking: const Move.cycle(_walk, gear: [Gear.floor]),
  CardioType.cycling: const Move.cycle(_cycle, gear: [Gear.bike, Gear.floor]),
  CardioType.elliptical: const Move.cycle(_elliptical, gear: [Gear.pedals, Gear.post, Gear.floor]),
  CardioType.stairs: const Move.cycle(_climb, gear: [Gear.floor]),
  CardioType.rowing: const Move.cycle(_row, gear: [Gear.seat, Gear.plateFeet, Gear.cableFront]),
  CardioType.swimming: const Move.cycle(_swim, gear: [Gear.water]),
  // A bodyweight squat: hips back and down, chest forward over the feet,
  // arms out in front for balance; up to standing with the arms down.
  CardioType.hiit: const Move(
    start: Pose(hip: Offset(42, 68), torso: 42, arm: Limb(75, 70), leg: Limb(72, -22)),
    end: Pose(hip: Offset(50, 55), torso: 6, arm: Limb(12, 12), leg: Limb(4, 0)),
    gear: [Gear.floor],
  ),
  CardioType.yoga: const Move(
    start: Pose(hip: Offset(50, 55), arm: Limb(20, 160)),
    end: Pose(hip: Offset(48, 56), torso: 100),
    gear: [Gear.floor],
  ),
  // A reach: arms swing up overhead, rising onto the toes, and back down.
  CardioType.other: const Move(
    start: Pose(hip: Offset(50, 56), arm: Limb(12, 14), leg: Limb(2, 0)),
    end: Pose(hip: Offset(50, 52), torso: -6, arm: Limb(178, 176), leg: Limb(2, 0)),
    gear: [Gear.floor],
  ),
};

Move? moveFor(String name) => exerciseMoves[name];
