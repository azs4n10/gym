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
  water,
  rail,
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
    this.foot,
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

  /// Heel raise in degrees, when the foot matters: 0 is flat on the ground,
  /// positive lifts the heel, negative drops it below the toes.
  final double? foot;

  Pose copyWith({
    Offset? hip,
    double? torso,
    Limb? arm,
    Limb? leg,
    Limb? arm2,
    Limb? leg2,
    double? foot,
  }) =>
      Pose(
        hip: hip ?? this.hip,
        torso: torso ?? this.torso,
        arm: arm ?? this.arm,
        leg: leg ?? this.leg,
        arm2: arm2 ?? this.arm2,
        leg2: leg2 ?? this.leg2,
        foot: foot ?? this.foot,
      );

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        hip: Offset.lerp(a.hip, b.hip, t)!,
        torso: a.torso + (b.torso - a.torso) * t,
        arm: Limb.lerp(a.arm, b.arm, t),
        leg: Limb.lerp(a.leg, b.leg, t),
        arm2: a.arm2 != null && b.arm2 != null ? Limb.lerp(a.arm2!, b.arm2!, t) : null,
        leg2: a.leg2 != null && b.leg2 != null ? Limb.lerp(a.leg2!, b.leg2!, t) : null,
        foot: a.foot != null && b.foot != null ? a.foot! + (b.foot! - a.foot!) * t : null,
      );
}

/// A movement. A lift is two poses played back and forth; a stride or a
/// stroke is a cycle, sampled from a function of phase and played forward.
class Move {
  const Move({required this.start, required this.end, this.gear = const [], this.view = Facing.side})
      : frames = const [],
        cycle = null;

  /// Several poses played back and forth, in order.
  const Move.frames(this.frames, {this.gear = const [], this.view = Facing.side})
      : start = null,
        end = null,
        cycle = null;

  /// A looping motion: [cycle] gives the pose at a phase from 0 to 2π.
  const Move.cycle(this.cycle, {this.gear = const [], this.view = Facing.side})
      : frames = const [],
        start = null,
        end = null;

  final Pose? start;
  final Pose? end;
  final List<Pose> frames;
  final Pose Function(double phase)? cycle;
  final List<Gear> gear;
  final Facing view;

  bool get loops => cycle != null;

  /// Pose at [t] in 0..1. For back-and-forth moves the controller reverses,
  /// so 0..1 runs the movement once through.
  Pose at(double t) {
    if (cycle != null) return cycle!(t * 2 * math.pi);
    final list = frames.isNotEmpty ? frames : [start!, end!];
    if (list.length == 1) return list.first;
    final scaled = t.clamp(0.0, 1.0) * (list.length - 1);
    final i = scaled.floor().clamp(0, list.length - 2);
    return Pose.lerp(list[i], list[i + 1], scaled - i);
  }
}

// Segment lengths, in the 100x100 box.
const torsoLen = 30.0;
const _headLen = 11.0;
const _headR = 7.5;
const upperArmLen = 14.0;
const forearmLen = 13.0;
const thighLen = 18.0;
const shinLen = 17.0;
const footLen = 12.0;

/// Where the floor is drawn. Poses put their feet just above it.
const floorY = 94.0;

Offset dirOf(double deg) {
  final r = deg * math.pi / 180;
  return Offset(math.sin(r), math.cos(r));
}

/// Angle, in this file's convention, of a direction vector.
double angleOf(Offset d) => math.atan2(d.dx, d.dy) * 180 / math.pi;

/// Joint positions worked out from a pose.
class Skeleton {
  Skeleton(Pose p, {bool front = false}) {
    hip = p.hip;
    final up = dirOf(180 - p.torso);
    neck = hip + up * torsoLen;
    head = neck + up * _headLen;
    elbow = neck + dirOf(p.arm.upper) * upperArmLen;
    hand = elbow + dirOf(p.arm.lower) * forearmLen;
    knee = hip + dirOf(p.leg.upper) * thighLen;
    ankle = knee + dirOf(p.leg.lower) * shinLen;
    if (p.foot != null) toe = ankle + dirOf(90 - p.foot!) * footLen;

    // Far side. From the front it is the opposite limb, so its "forward"
    // points the other way.
    final flip = front ? -1.0 : 1.0;
    Offset far(double deg) {
      final d = dirOf(deg);
      return Offset(d.dx * flip, d.dy);
    }

    final a2 = p.arm2 ?? (front ? p.arm : null);
    final l2 = p.leg2 ?? (front ? p.leg : null);
    if (a2 != null) {
      elbow2 = neck + far(a2.upper) * upperArmLen;
      hand2 = elbow2! + far(a2.lower) * forearmLen;
    }
    if (l2 != null) {
      knee2 = hip + far(l2.upper) * thighLen;
      ankle2 = knee2! + far(l2.lower) * shinLen;
    }
  }

  late final Offset hip, neck, head, elbow, hand, knee, ankle;
  Offset? elbow2, hand2, knee2, ankle2, toe;
}

/// What the face shows; none keeps the plain head the exercise list uses.
enum FigureFace { none, smile, focus, push, rest }

/// Something worn on the head; unlocked with stamps in the run companion.
enum FigureHat { none, cap, beanie, crown, flower }

/// Draws a movement. Static by default; [animate] plays it.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({
    super.key,
    required this.move,
    this.size = 64,
    this.animate = false,
    this.color,
    this.gearColor,
    this.phase = 0,
    this.bold = false,
    this.t,
    this.face = FigureFace.none,
    this.hat = FigureHat.none,
    this.shirt,
    this.faceColor,
    this.hatColor,
    this.outline,
  });

  final Move move;

  /// A light rim drawn behind the body, so the figure stays readable over a
  /// busy or dark backdrop, the way a sticker is cut with a white edge.
  final Color? outline;

  /// Expression, hat and shirt colour for the companion; the exercise list
  /// leaves them off.
  final FigureFace face;
  final FigureHat hat;
  final Color? shirt;
  final Color? faceColor;
  final Color? hatColor;
  final double size;
  final bool animate;
  final Color? color;

  /// Heavier strokes and a bigger head, for icon sizes.
  final bool bold;

  /// Colour of the bench, bar and floor; must contrast with the backdrop.
  final Color? gearColor;

  /// 0-1 offset into the loop, so neighbouring rows do not move as one.
  final double phase;

  /// When given, the figure is drawn at exactly this point of its motion and
  /// does not run its own clock; the caller advances it.
  final double? t;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.t == null) {
      final loops = widget.move.loops;
      _c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: loops ? 1300 : 900),
      )
        ..value = widget.phase.clamp(0.0, 1.0)
        ..repeat(reverse: !loops);
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
    final loops = widget.move.loops;
    _FigurePainter painter(double t) => _FigurePainter(
          pose: widget.move.at(loops ? t : Curves.easeInOut.transform(t)),
          gear: widget.move.gear,
          view: widget.move.view,
          ink: widget.color ?? skin.ink,
          kit: widget.gearColor ?? skin.button,
          bold: widget.bold,
          face: widget.face,
          hat: widget.hat,
          shirt: widget.shirt,
          faceColor: widget.faceColor ?? skin.card,
          hatColor: widget.hatColor ?? skin.accent,
          outline: widget.outline,
        );
    final c = _c;
    final fixed = widget.t;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: fixed != null
          ? CustomPaint(painter: painter(fixed % 1.0))
          : c == null
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
    this.bold = false,
    this.face = FigureFace.none,
    this.hat = FigureHat.none,
    this.shirt,
    this.faceColor = const Color(0xFFFFFFFF),
    this.hatColor = const Color(0xFFFBBBD3),
    this.outline,
  });

  final Pose pose;
  final List<Gear> gear;
  final Facing view;
  final Color ink;
  final Color kit;
  final bool bold;
  final FigureFace face;
  final FigureHat hat;
  final Color? shirt;
  final Color faceColor;
  final Color hatColor;
  final Color? outline;

  bool has(Gear g) => gear.contains(g);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final s = Skeleton(pose, front: view == Facing.front);
    final w = bold ? 11.0 : 6.0;
    final limb = _line(ink, w);
    final farLimb = _line(ink.withValues(alpha: view == Facing.front ? 1 : 0.5), w);

    _behind(canvas, s);

    if (outline case final oc?) {
      final halo = _line(oc, w + 5);
      if (s.elbow2 != null) _stroke(canvas, [s.neck, s.elbow2!, s.hand2!], halo);
      if (s.knee2 != null) _stroke(canvas, [s.hip, s.knee2!, s.ankle2!], halo);
      canvas.drawLine(s.neck, s.hip, halo);
      _stroke(canvas, [s.neck, s.elbow, s.hand], halo);
      _stroke(canvas, [s.hip, s.knee, s.ankle, if (s.toe != null) s.toe!], halo);
      canvas.drawCircle(s.head, (bold ? 10.5 : _headR) + 2.5, Paint()..color = oc);
    }

    if (s.elbow2 != null) _stroke(canvas, [s.neck, s.elbow2!, s.hand2!], farLimb);
    if (s.knee2 != null) _stroke(canvas, [s.hip, s.knee2!, s.ankle2!], farLimb);
    canvas.drawLine(s.neck, s.hip, limb);
    if (shirt case final c?) {
      // A coloured band over the torso, inside the ink outline.
      canvas.drawLine(s.neck, s.hip, _line(c, w - 2.4));
    }
    _stroke(canvas, [s.neck, s.elbow, s.hand], limb);
    _stroke(canvas, [s.hip, s.knee, s.ankle, if (s.toe != null) s.toe!], limb);

    _held(canvas, s);
    canvas.drawCircle(s.head, bold ? 10.5 : _headR, Paint()..color = ink);
    _face(canvas, s);
    _hat(canvas, s);
  }

  /// Eyes and mouth on the head, toward the front (+x from the side, both
  /// sides from the front).
  void _face(Canvas canvas, Skeleton s) {
    if (face == FigureFace.none) return;
    final front = view == Facing.front;
    final eye = Paint()..color = faceColor;
    final lineP = _line(faceColor, 1.4);
    final eyes = front ? [s.head + const Offset(-2.6, -1.2), s.head + const Offset(2.6, -1.2)] : [s.head + const Offset(3.2, -1.4)];
    for (final e in eyes) {
      if (face == FigureFace.rest) {
        // Closed: a short curved line.
        final p = Path()..moveTo(e.dx - 1.6, e.dy);
        p.quadraticBezierTo(e.dx, e.dy + 1.6, e.dx + 1.6, e.dy);
        canvas.drawPath(p, lineP);
      } else {
        canvas.drawCircle(e, face == FigureFace.push ? 1.5 : 1.2, eye);
      }
    }
    final m = front ? s.head + const Offset(0, 3.2) : s.head + const Offset(3.6, 3.0);
    switch (face) {
      case FigureFace.smile:
        final p = Path()..moveTo(m.dx - 2.2, m.dy - 0.6);
        p.quadraticBezierTo(m.dx, m.dy + 1.8, m.dx + 2.2, m.dy - 0.6);
        canvas.drawPath(p, lineP);
      case FigureFace.focus:
        canvas.drawLine(m + const Offset(-1.8, 0), m + const Offset(1.8, 0), lineP);
      case FigureFace.push:
        canvas.drawCircle(m, 1.7, eye);
        // A drop of sweat off the back of the head.
        final d = s.head + (front ? const Offset(-8.5, -3) : const Offset(-7.5, -3));
        canvas.drawCircle(d, 1.4, Paint()..color = kit);
      case FigureFace.rest:
        final p = Path()..moveTo(m.dx - 1.6, m.dy);
        p.quadraticBezierTo(m.dx, m.dy + 1.2, m.dx + 1.6, m.dy);
        canvas.drawPath(p, lineP);
      case FigureFace.none:
        break;
    }
  }

  /// The half of the plane on the head's "up" side of [base], so a hat is cut
  /// along the tilt of the head rather than the screen.
  Path _above(Offset base, Offset up, Offset side) => Path()
    ..addPolygon([
      base + side * 40,
      base - side * 40,
      base - side * 40 + up * 40,
      base + side * 40 + up * 40,
    ], true);

  void _hat(Canvas canvas, Skeleton s) {
    if (hat == FigureHat.none) return;
    final r = bold ? 10.5 : _headR;
    final up = (s.head - s.neck) / (s.head - s.neck).distance;
    final side = Offset(-up.dy, up.dx) * (view == Facing.front ? 1 : 1);
    final top = s.head + up * r;
    final fill = Paint()..color = hatColor;
    final edge = _line(ink, 1.6);
    switch (hat) {
      case FigureHat.cap:
        final dome = Path()..addArc(Rect.fromCircle(center: s.head + up * 1.5, radius: r + 1.2), 0, 2 * math.pi);
        canvas.save();
        canvas.clipPath(_above(s.head - up * 0.5, up, side));
        canvas.drawPath(dome, fill);
        canvas.drawPath(dome, edge);
        canvas.restore();
        // Brim toward the front.
        final brimFrom = s.head + side * (r - 1) - up * 0.5;
        canvas.drawLine(brimFrom, brimFrom + side * 7 + up * 1.2, _line(ink, 2.6));
        canvas.drawLine(brimFrom, brimFrom + side * 7 + up * 1.2, _line(hatColor, 1.2));
      case FigureHat.beanie:
        final dome = Path()..addArc(Rect.fromCircle(center: s.head + up * 2.5, radius: r + 1.6), 0, 2 * math.pi);
        canvas.save();
        canvas.clipPath(_above(s.head + up * 1.0, up, side));
        canvas.drawPath(dome, fill);
        canvas.drawPath(dome, edge);
        canvas.restore();
        canvas.drawLine(s.head + up * 1.6 - side * (r + 1.2), s.head + up * 1.6 + side * (r + 1.2), _line(ink, 2.4));
        canvas.drawCircle(top + up * 3.2, 2.2, fill);
        canvas.drawCircle(top + up * 3.2, 2.2, edge);
      case FigureHat.crown:
        final base = s.head + up * (r - 1.5);
        final pts = <Offset>[];
        const n = 4;
        for (var i = 0; i <= n; i++) {
          final x = -6.0 + 12.0 * i / n;
          pts.add(base + side * x + up * (i.isEven ? 5.5 : 1.5));
        }
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        final lo = base + side * 6;
        final lo2 = base - side * 6;
        path.lineTo(lo.dx, lo.dy);
        path.lineTo(lo2.dx, lo2.dy);
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, edge);
      case FigureHat.flower:
        final c = s.head + up * (r - 1) + side * 3.5;
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * math.pi / 5;
          canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 2.6, 1.7, fill);
          canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 2.6, 1.7, _line(ink, 0.9));
        }
        canvas.drawCircle(c, 1.5, Paint()..color = kit);
      case FigureHat.none:
        break;
    }
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
      canvas.drawLine(const Offset(4, floorY), const Offset(96, floorY), mid);
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
      canvas.drawRRect(RRect.fromLTRBR(4, 20, 14, floorY, const Radius.circular(4)), fill);
    }
    if (has(Gear.post)) {
      canvas.drawLine(const Offset(84, 16), const Offset(84, floorY), thin);
    }
    if (has(Gear.rail)) {
      final x = s.hand.dx + 5;
      canvas.drawLine(Offset(x, 16), Offset(x, floorY), thin);
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
      canvas.drawLine(Offset(postX, top + 7), Offset(postX, floorY), thin);
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
        canvas.drawLine(p, Offset(p.dx, floorY), thin);
      }
    }
    if (has(Gear.benchShoulders)) {
      final y = s.neck.dy + 7;
      canvas.drawLine(Offset(s.neck.dx - 8, y), Offset(s.neck.dx + 14, y), thick);
      for (final x in [s.neck.dx - 8, s.neck.dx + 14]) {
        canvas.drawLine(Offset(x, y), Offset(x, floorY), thin);
      }
    }
    if (has(Gear.benchHand2) && s.hand2 != null) {
      final h = s.hand2!;
      canvas.drawLine(Offset(h.dx - 10, h.dy + 4), Offset(h.dx + 10, h.dy + 4), thick);
      canvas.drawLine(Offset(h.dx, h.dy + 4), Offset(h.dx, floorY), thin);
    }
    if (has(Gear.benchFoot2) && s.ankle2 != null) {
      final a = s.ankle2!;
      canvas.drawLine(Offset(a.dx - 8, a.dy + 4), Offset(a.dx + 8, a.dy + 4), thick);
      canvas.drawLine(Offset(a.dx, a.dy + 4), Offset(a.dx, floorY), thin);
    }
    if (has(Gear.pedals)) {
      for (final a in [s.ankle, if (s.ankle2 != null) s.ankle2!]) {
        canvas.drawLine(Offset(a.dx - 7, a.dy + 4), Offset(a.dx + 7, a.dy + 4), mid);
      }
    }
    if (has(Gear.bike)) {
      final rear = Offset(s.hip.dx - 22, 82);
      final front = Offset(s.hand.dx + 4, 82);
      final crank = Offset(s.hip.dx + 6, 78);
      canvas.drawCircle(rear, 11, cable);
      canvas.drawCircle(front, 11, cable);
      _stroke(canvas, [rear, crank, s.hip + const Offset(-2, 5), rear], thin);
      _stroke(canvas, [s.hip + const Offset(-2, 5), Offset(s.hand.dx - 2, s.hand.dy + 6), front], thin);
      canvas.drawLine(crank, Offset(s.hand.dx - 2, s.hand.dy + 6), thin);
    }
    if (has(Gear.pullBar)) {
      canvas.drawLine(Offset(10, s.hand.dy), Offset(90, s.hand.dy), mid);
    }
    if (has(Gear.dipBars)) {
      final y = s.hand.dy;
      canvas.drawLine(Offset(s.hand.dx - 12, y), Offset(s.hand.dx + 12, y), mid);
      canvas.drawLine(Offset(s.hand.dx, y), Offset(s.hand.dx, floorY), thin);
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
    if (has(Gear.calfBlock) && s.toe != null) {
      // A step under the toes; the heel hangs off the back of it.
      final t = s.toe!;
      canvas.drawRRect(
        RRect.fromLTRBR(t.dx - 6, t.dy + 3, t.dx + 10, floorY, const Radius.circular(2)),
        fill,
      );
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
      for (final p in [at, if (both) _mirror(at)]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 10, height: 10),
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
