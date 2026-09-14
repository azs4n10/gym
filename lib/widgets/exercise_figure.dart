import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// Which way the figure faces. Side-on for most lifts; front-on for movements
/// that happen out to the sides, which a side view cannot show.
enum Facing { side, front }

/// Equipment, placed relative to the body at paint time.
enum Gear {
  floor,
  seat,
  bench,
  benchShoulders,
  benchHand2,
  benchFoot2,
  barbell,
  dumbbell,
  dumbbellUpright,
  barbellShoulders,
  barbellHip,
  pullBar,
  dipBars,
  cableHigh,
  cableLow,
  cableFront,
  cableAnkle,
  padAnkle,
  padKnee,
  padHand,
  plateFeet,
  frame,
  post,
  wheel,
  bike,
  pedals,
  step,
  water,
  foot,
  calfBlock,
  padKneeOuter,
  padKneeInner,
}

/// Two joint angles in degrees, measured from straight down; positive swings
/// the limb forward (or, seen from the front, out to the side).
class Limb {
  const Limb(this.upper, this.lower);
  final double upper;
  final double lower;

  static Limb lerp(Limb a, Limb b, double t) =>
      Limb(a.upper + (b.upper - a.upper) * t, a.lower + (b.lower - a.lower) * t);
}

/// A body position described by angles. Segment lengths are fixed, so a pose
/// can only be somewhere a body can actually be.
class Pose {
  const Pose({
    this.hip = const Offset(50, 55),
    this.torso = 0,
    this.arm = const Limb(0, 0),
    this.leg = const Limb(0, 0),
    this.arm2,
    this.leg2,
  });

  /// Where the hip sits in the 100x100 box.
  final Offset hip;

  /// Torso angle from upright; positive leans forward, 90 is lying with the
  /// head toward the front.
  final double torso;

  final Limb arm;
  final Limb leg;

  /// Far-side limbs, drawn behind. Seen from the front they are the other
  /// side of the body; when omitted the near limbs are mirrored.
  final Limb? arm2;
  final Limb? leg2;

  Pose copyWith({
    Offset? hip,
    double? torso,
    Limb? arm,
    Limb? leg,
    Limb? arm2,
    Limb? leg2,
  }) =>
      Pose(
        hip: hip ?? this.hip,
        torso: torso ?? this.torso,
        arm: arm ?? this.arm,
        leg: leg ?? this.leg,
        arm2: arm2 ?? this.arm2,
        leg2: leg2 ?? this.leg2,
      );

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        hip: Offset.lerp(a.hip, b.hip, t)!,
        torso: a.torso + (b.torso - a.torso) * t,
        arm: Limb.lerp(a.arm, b.arm, t),
        leg: Limb.lerp(a.leg, b.leg, t),
        arm2: a.arm2 != null && b.arm2 != null ? Limb.lerp(a.arm2!, b.arm2!, t) : null,
        leg2: a.leg2 != null && b.leg2 != null ? Limb.lerp(a.leg2!, b.leg2!, t) : null,
      );
}

class Move {
  const Move({
    required this.start,
    required this.end,
    this.gear = const [],
    this.view = Facing.side,
  });
  final Pose start;
  final Pose end;
  final List<Gear> gear;
  final Facing view;
}

// Segment lengths, in the 100x100 box.
const _torsoLen = 30.0;
const _headLen = 11.0;
const _headR = 7.5;
const _upperArm = 14.0;
const _forearm = 13.0;
const _thigh = 18.0;
const _shin = 17.0;

/// Where the floor is drawn. Poses put their feet just above it.
const _floorY = 94.0;

Offset _dir(double deg) {
  final r = deg * math.pi / 180;
  return Offset(math.sin(r), math.cos(r));
}

/// Joint positions worked out from a pose.
class Skeleton {
  Skeleton(Pose p, {bool front = false}) {
    hip = p.hip;
    final up = _dir(180 - p.torso);
    neck = hip + up * _torsoLen;
    head = neck + up * _headLen;
    elbow = neck + _dir(p.arm.upper) * _upperArm;
    hand = elbow + _dir(p.arm.lower) * _forearm;
    knee = hip + _dir(p.leg.upper) * _thigh;
    ankle = knee + _dir(p.leg.lower) * _shin;

    // Far side. From the front it is the opposite limb, so its "forward"
    // points the other way.
    final flip = front ? -1.0 : 1.0;
    Offset far(double deg) {
      final d = _dir(deg);
      return Offset(d.dx * flip, d.dy);
    }

    final a2 = p.arm2 ?? (front ? p.arm : null);
    final l2 = p.leg2 ?? (front ? p.leg : null);
    if (a2 != null) {
      elbow2 = neck + far(a2.upper) * _upperArm;
      hand2 = elbow2! + far(a2.lower) * _forearm;
    }
    if (l2 != null) {
      knee2 = hip + far(l2.upper) * _thigh;
      ankle2 = knee2! + far(l2.lower) * _shin;
    }
  }

  late final Offset hip, neck, head, elbow, hand, knee, ankle;
  Offset? elbow2, hand2, knee2, ankle2;
}

/// Draws a movement. Static by default; [animate] loops between the poses.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({
    super.key,
    required this.move,
    this.size = 64,
    this.animate = false,
    this.color,
    this.gearColor,
    this.phase = 0,
  });

  final Move move;
  final double size;
  final bool animate;
  final Color? color;

  /// Colour of the bench, bar and floor; must contrast with the backdrop.
  final Color? gearColor;

  /// 0-1 offset into the loop, so neighbouring rows do not move as one.
  final double phase;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..value = widget.phase.clamp(0.0, 1.0)
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    _FigurePainter painter(double t) => _FigurePainter(
          pose: Pose.lerp(widget.move.start, widget.move.end, Curves.easeInOut.transform(t)),
          gear: widget.move.gear,
          view: widget.move.view,
          ink: widget.color ?? skin.ink,
          kit: widget.gearColor ?? skin.button,
        );
    final c = _c;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: c == null
          ? CustomPaint(painter: painter(0), isComplex: true, willChange: false)
          : RepaintBoundary(
              child: AnimatedBuilder(
                animation: c,
                builder: (_, _) => CustomPaint(painter: painter(c.value)),
              ),
            ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  const _FigurePainter({
    required this.pose,
    required this.gear,
    required this.view,
    required this.ink,
    required this.kit,
  });

  final Pose pose;
  final List<Gear> gear;
  final Facing view;
  final Color ink;
  final Color kit;

  bool has(Gear g) => gear.contains(g);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final s = Skeleton(pose, front: view == Facing.front);
    final limb = _line(ink, 6);
    final farLimb = _line(ink.withValues(alpha: view == Facing.front ? 1 : 0.55), 6);

    _behind(canvas, s);

    if (s.elbow2 != null) _stroke(canvas, [s.neck, s.elbow2!, s.hand2!], farLimb);
    if (s.knee2 != null) _stroke(canvas, [s.hip, s.knee2!, s.ankle2!], farLimb);
    canvas.drawLine(s.neck, s.hip, limb);
    _stroke(canvas, [s.neck, s.elbow, s.hand], limb);
    _stroke(canvas, [s.hip, s.knee, s.ankle], limb);

    _held(canvas, s);
    canvas.drawCircle(s.head, _headR, Paint()..color = ink);
  }

  Paint _line(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _stroke(Canvas canvas, List<Offset> pts, Paint p) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, p);
  }

  /// Equipment the body rests on or against.
  void _behind(Canvas canvas, Skeleton s) {
    final fill = Paint()..color = kit;
    final thick = _line(kit, 8);
    final mid = _line(kit, 6);
    final thin = _line(kit, 4);
    final cable = _line(kit, 3);

    if (has(Gear.floor)) {
      canvas.drawLine(const Offset(4, _floorY), const Offset(96, _floorY), mid);
    }
    if (has(Gear.water)) {
      final y = s.hip.dy + 3;
      final path = Path()..moveTo(2, y);
      for (var x = 2.0; x < 98; x += 12) {
        path.quadraticBezierTo(x + 3, y - 3, x + 6, y);
        path.quadraticBezierTo(x + 9, y + 3, x + 12, y);
      }
      canvas.drawPath(path, cable);
    }
    if (has(Gear.frame)) {
      canvas.drawRRect(RRect.fromLTRBR(4, 20, 14, _floorY, const Radius.circular(4)), fill);
    }
    if (has(Gear.post)) {
      final x = s.hand.dx + 5;
      canvas.drawLine(Offset(x, 18), Offset(x, _floorY), thin);
    }
    if (has(Gear.seat)) {
      // Pad under the hips reaching toward the knee, on a post.
      final forward = s.knee.dx >= s.hip.dx;
      final front = forward ? s.knee.dx + 2 : s.hip.dx + 10;
      final back = forward ? s.hip.dx - 12 : s.knee.dx - 2;
      final top = s.hip.dy + 3;
      canvas.drawRRect(
        RRect.fromLTRBR(back, top, front, top + 7, const Radius.circular(3.5)),
        fill,
      );
      final postX = (back + front) / 2;
      canvas.drawLine(Offset(postX, top + 7), Offset(postX, _floorY), thin);
    }
    if (has(Gear.bench)) {
      // A pad along the back of the torso: the side the arm is not on.
      final along = s.neck - s.hip;
      final unit = along / along.distance;
      var normal = Offset(-unit.dy, unit.dx);
      final toElbow = s.elbow - s.neck;
      if (normal.dx * toElbow.dx + normal.dy * toElbow.dy > 0) normal = -normal;
      final off = normal * 7;
      final a = s.hip - unit * 8 + off;
      final b = s.neck + unit * 12 + off;
      canvas.drawLine(a, b, thick);
      for (final p in [a, b]) {
        canvas.drawLine(p, Offset(p.dx, _floorY), thin);
      }
    }
    if (has(Gear.benchShoulders)) {
      final y = s.neck.dy + 7;
      canvas.drawLine(Offset(s.neck.dx - 8, y), Offset(s.neck.dx + 14, y), thick);
      for (final x in [s.neck.dx - 8, s.neck.dx + 14]) {
        canvas.drawLine(Offset(x, y), Offset(x, _floorY), thin);
      }
    }
    if (has(Gear.benchHand2) && s.hand2 != null) {
      final h = s.hand2!;
      canvas.drawLine(Offset(h.dx - 10, h.dy + 4), Offset(h.dx + 10, h.dy + 4), thick);
      canvas.drawLine(Offset(h.dx, h.dy + 4), Offset(h.dx, _floorY), thin);
    }
    if (has(Gear.benchFoot2) && s.ankle2 != null) {
      final a = s.ankle2!;
      canvas.drawLine(Offset(a.dx - 8, a.dy + 4), Offset(a.dx + 8, a.dy + 4), thick);
      canvas.drawLine(Offset(a.dx, a.dy + 4), Offset(a.dx, _floorY), thin);
    }
    if (has(Gear.step)) {
      canvas.drawRRect(
        RRect.fromLTRBR(s.ankle.dx - 8, s.ankle.dy + 3, s.ankle.dx + 12, _floorY, const Radius.circular(3)),
        fill,
      );
    }
    if (has(Gear.pedals)) {
      for (final a in [s.ankle, if (s.ankle2 != null) s.ankle2!]) {
        canvas.drawLine(Offset(a.dx - 7, a.dy + 4), Offset(a.dx + 7, a.dy + 4), mid);
      }
    }
    if (has(Gear.bike)) {
      final rear = Offset(s.hip.dx - 20, 83);
      final front = Offset(s.hand.dx + 6, 83);
      canvas.drawCircle(rear, 10, cable);
      canvas.drawCircle(front, 10, cable);
      final crank = Offset(s.hip.dx + 8, 76);
      _stroke(canvas, [rear, crank, s.hip + const Offset(-4, 4), rear], thin);
      _stroke(canvas, [crank, Offset(s.hand.dx, s.hand.dy + 4), front], thin);
    }
    if (has(Gear.pullBar)) {
      canvas.drawLine(Offset(10, s.hand.dy), Offset(90, s.hand.dy), mid);
    }
    if (has(Gear.dipBars)) {
      final y = s.hand.dy;
      canvas.drawLine(Offset(s.hand.dx - 12, y), Offset(s.hand.dx + 12, y), mid);
      canvas.drawLine(Offset(s.hand.dx, y), Offset(s.hand.dx, _floorY), thin);
    }
    if (has(Gear.cableHigh)) {
      _cable(canvas, const Offset(92, 8), s.hand, cable, fill);
      if (view == Facing.front) _cable(canvas, const Offset(8, 8), _mirror(s.hand), cable, fill);
    }
    if (has(Gear.cableLow)) {
      _cable(canvas, const Offset(92, 92), s.hand, cable, fill);
      if (view == Facing.front) _cable(canvas, const Offset(8, 92), _mirror(s.hand), cable, fill);
    }
    if (has(Gear.cableFront)) {
      _cable(canvas, Offset(96, s.hand.dy), s.hand, cable, fill);
    }
    if (has(Gear.cableAnkle)) {
      _cable(canvas, const Offset(92, 92), s.ankle, cable, fill);
    }
    if (has(Gear.calfBlock)) {
      canvas.drawRRect(
        RRect.fromLTRBR(s.ankle.dx + 4, 86, s.ankle.dx + 18, _floorY, const Radius.circular(2)),
        fill,
      );
    }
    if (has(Gear.foot)) {
      // Toes stay put on the block, so a raised ankle reads as a lifted heel.
      canvas.drawLine(s.ankle, Offset(s.ankle.dx + 11, 85), _line(ink, 6));
    }
    if (has(Gear.plateFeet)) {
      // A platform square to the shin.
      final d = s.ankle - s.knee;
      final n = Offset(-d.dy, d.dx) / d.distance * 12;
      final c = s.ankle + d / d.distance * 4;
      canvas.drawLine(c - n, c + n, _line(kit, 5));
    }
  }

  Offset _mirror(Offset o) => Offset(100 - o.dx, o.dy);

  void _cable(Canvas canvas, Offset pulley, Offset to, Paint line, Paint fill) {
    canvas.drawLine(pulley, to, line);
    canvas.drawCircle(pulley, 5, fill);
  }

  /// Equipment in the hands, or pads pressed against a joint.
  void _held(Canvas canvas, Skeleton s) {
    final fill = Paint()..color = kit;
    final both = view == Facing.front;
    void pad(Offset at) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: 10, height: 10),
          const Radius.circular(3),
        ),
        fill,
      );
      if (both) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: _mirror(at), width: 10, height: 10),
            const Radius.circular(3),
          ),
          fill,
        );
      }
    }

    if (has(Gear.padAnkle)) pad(s.ankle);
    if (has(Gear.padKnee)) pad(s.knee);
    if (has(Gear.padKneeOuter)) pad(s.knee + const Offset(7, 0));
    if (has(Gear.padKneeInner)) pad(s.knee + const Offset(-7, 0));
    if (has(Gear.padHand)) pad(s.hand);
    if (has(Gear.wheel)) {
      canvas.drawCircle(s.hand + const Offset(0, 6), 6, fill);
      canvas.drawCircle(s.hand + const Offset(0, 6), 6, _line(ink, 2));
    }

    if (has(Gear.barbell)) _barbell(canvas, s.hand, fill);
    if (has(Gear.barbellShoulders)) _barbell(canvas, s.neck, fill);
    if (has(Gear.barbellHip)) _barbell(canvas, s.hip, fill);
    if (has(Gear.dumbbell) || has(Gear.dumbbellUpright)) {
      final upright = has(Gear.dumbbellUpright);
      _dumbbell(canvas, s.hand, fill, upright: upright);
      if (both) _dumbbell(canvas, _mirror(s.hand), fill, upright: upright);
    }
  }

  /// Long bar with a plate at each end, drawn the same from any angle so it
  /// reads as a barbell at a glance.
  void _barbell(Canvas canvas, Offset at, Paint fill) {
    final bar = _line(ink, 3);
    canvas.drawLine(Offset(at.dx - 17, at.dy), Offset(at.dx + 17, at.dy), bar);
    final edge = _line(ink, 2);
    for (final dx in [-14.0, 14.0]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(at.dx + dx, at.dy), width: 6, height: 15),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, edge);
    }
  }

  /// Short bar with a round head at each end. Upright for a hammer grip.
  void _dumbbell(Canvas canvas, Offset at, Paint fill, {required bool upright}) {
    final bar = _line(ink, 2.5);
    final edge = _line(ink, 1.8);
    final d = upright ? const Offset(0, 6) : const Offset(6, 0);
    canvas.drawLine(at - d, at + d, bar);
    for (final sgn in [-1.0, 1.0]) {
      canvas.drawCircle(at + d * sgn, 4, fill);
      canvas.drawCircle(at + d * sgn, 4, edge);
    }
  }

  @override
  bool shouldRepaint(_FigurePainter old) => true;
}
