import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// Equipment drawn around the figure.
enum Gear { bench, barbellHands, barbellShoulders, dumbbells, pullBar, floor }

/// One side-on pose, in a 100x100 box. Only one arm and one leg are drawn:
/// exercise diagrams read better in profile, and it keeps the lines few enough
/// to stay legible at thumbnail size.
class Pose {
  const Pose({
    required this.head,
    required this.neck,
    required this.hip,
    required this.elbow,
    required this.hand,
    required this.knee,
    required this.ankle,
    this.headR = 8,
  });

  final Offset head;
  final Offset neck;
  final Offset hip;
  final Offset elbow;
  final Offset hand;
  final Offset knee;
  final Offset ankle;
  final double headR;

  static Offset _l(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        head: _l(a.head, b.head, t),
        neck: _l(a.neck, b.neck, t),
        hip: _l(a.hip, b.hip, t),
        elbow: _l(a.elbow, b.elbow, t),
        hand: _l(a.hand, b.hand, t),
        knee: _l(a.knee, b.knee, t),
        ankle: _l(a.ankle, b.ankle, t),
        headR: a.headR + (b.headR - a.headR) * t,
      );
}

class Move {
  const Move({required this.start, required this.end, this.gear = const []});
  final Pose start;
  final Pose end;
  final List<Gear> gear;
}

/// Draws a movement. Static by default; [animate] loops between the two poses,
/// which is only worth paying for on a single large figure, not a whole list.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({
    super.key,
    required this.move,
    this.size = 64,
    this.animate = false,
    this.color,
  });

  final Move move;
  final double size;
  final bool animate;
  final Color? color;

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
      _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
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
    final ink = widget.color ?? skin.ink;
    _FigurePainter painter(double t) => _FigurePainter(
          pose: Pose.lerp(widget.move.start, widget.move.end, Curves.easeInOut.transform(t)),
          gear: widget.move.gear,
          ink: ink,
          accent: skin.button,
        );
    final c = _c;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: c == null
          ? CustomPaint(painter: painter(0), isComplex: true, willChange: false)
          : AnimatedBuilder(
              animation: c,
              builder: (_, _) => CustomPaint(painter: painter(c.value)),
            ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  const _FigurePainter({
    required this.pose,
    required this.gear,
    required this.ink,
    required this.accent,
  });

  final Pose pose;
  final List<Gear> gear;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final limb = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final kit = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final kitFill = Paint()..color = accent;

    if (gear.contains(Gear.floor)) {
      canvas.drawLine(const Offset(8, 92), const Offset(92, 92), kit);
    }
    if (gear.contains(Gear.bench)) {
      canvas.drawRRect(
        RRect.fromLTRBR(34, 62, 94, 71, const Radius.circular(4)),
        kitFill,
      );
      canvas.drawLine(const Offset(44, 71), const Offset(44, 90), kit);
      canvas.drawLine(const Offset(86, 71), const Offset(86, 90), kit);
    }
    if (gear.contains(Gear.pullBar)) {
      canvas.drawLine(const Offset(14, 10), const Offset(86, 10), kit);
    }

    // torso, then the near arm and leg
    canvas.drawLine(pose.neck, pose.hip, limb);
    canvas.drawPath(
      Path()
        ..moveTo(pose.neck.dx, pose.neck.dy)
        ..lineTo(pose.elbow.dx, pose.elbow.dy)
        ..lineTo(pose.hand.dx, pose.hand.dy),
      limb,
    );
    canvas.drawPath(
      Path()
        ..moveTo(pose.hip.dx, pose.hip.dy)
        ..lineTo(pose.knee.dx, pose.knee.dy)
        ..lineTo(pose.ankle.dx, pose.ankle.dy),
      limb,
    );
    if (gear.contains(Gear.barbellShoulders)) _bar(canvas, pose.neck, kitFill, kit);
    canvas.drawCircle(pose.head, pose.headR, Paint()..color = ink);
    if (gear.contains(Gear.barbellHands)) _bar(canvas, pose.hand, kitFill, kit);
    if (gear.contains(Gear.dumbbells)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pose.hand, width: 7, height: 20),
          const Radius.circular(3),
        ),
        kitFill,
      );
    }
  }

  /// Seen from the side the bar points at the viewer, so it reads as a plate.
  void _bar(Canvas canvas, Offset at, Paint fill, Paint stroke) {
    canvas.drawCircle(at, 9, fill);
    canvas.drawCircle(at, 9, stroke..strokeWidth = 2.5..color = ink);
    canvas.drawCircle(at, 3, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_FigurePainter old) => true;
}
