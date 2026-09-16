import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/exercise_moves.dart';
import '../models/run_play.dart';
import 'companion_sprite.dart';
import 'exercise_figure.dart';

/// A cut-out rig of the illustrated companion: the drawing split into a few
/// layers, each a small triangle mesh whose vertices follow the bones with
/// blended weights (built by tool scripts into assets/companion/rig). The
/// bones take their angles from the same [Pose] the stick figure uses, so
/// every cycle the app already has plays on the illustration, smoothly.
class CompanionRig {
  CompanionRig._(this.width, this.height, this.floor, this.crown, this.sole, this.bones, this.layers, this.hats);

  final double width;
  final double height;

  /// The line the feet stand on in the rest pose.
  final double floor;

  /// Top of the head in the rest pose, where hats sit.
  final Offset crown;

  /// Heel and toe of the sole, relative to a foot bone's head (the ankle).
  final List<Offset> sole;
  final List<RigBone> bones;
  final List<RigLayer> layers;

  /// The wardrobe's hat drawings by id.
  final Map<String, ui.Image> hats;

  static Future<CompanionRig>? _side;

  /// The side-view rig, loaded once.
  static Future<CompanionRig> side() => _side ??= _load('assets/companion/rig/side.json');

  static Future<CompanionRig> _load(String path) async {
    final json = jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
    final dir = path.substring(0, path.lastIndexOf('/'));
    final size = (json['size'] as List).cast<num>();
    final crown = (json['crown'] as List).cast<num>();
    final floor = (json['floor'] as num?)?.toDouble() ?? size[1] - 12;
    final sole = [
      for (final p in (json['sole'] as List? ?? const [[-40, 130], [90, 128]]).cast<List>())
        Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    final bones = [
      for (final b in (json['bones'] as List).cast<Map<String, dynamic>>())
        RigBone(
          name: b['name'] as String,
          parent: b['parent'] as int,
          head: Offset((b['head'][0] as num).toDouble(), (b['head'][1] as num).toDouble()),
          tail: Offset((b['tail'][0] as num).toDouble(), (b['tail'][1] as num).toDouble()),
        ),
    ];
    final layers = <RigLayer>[];
    // The arm and the leg are drawn once and used on both sides.
    final images = <String, ui.Image>{};
    for (final l in (json['layers'] as List).cast<Map<String, dynamic>>()) {
      final file = l['image'] as String;
      final image = images[file] ??= await () async {
        final bytes = await rootBundle.load('$dir/$file');
        return decodeImageFromList(bytes.buffer.asUint8List());
      }();
      final verts = (l['verts'] as List).cast<List>();
      final offset = (l['offset'] as List).cast<num>();
      final n = verts.length;
      final rest = Float32List(n * 2);
      final uv = Float32List(n * 2);
      for (var i = 0; i < n; i++) {
        rest[i * 2] = (verts[i][0] as num).toDouble();
        rest[i * 2 + 1] = (verts[i][1] as num).toDouble();
        uv[i * 2] = rest[i * 2] - offset[0];
        uv[i * 2 + 1] = rest[i * 2 + 1] - offset[1];
      }
      final tris = (l['tris'] as List).cast<int>();
      final weights = (l['weights'] as List).cast<List>();
      layers.add(RigLayer(
        name: l['name'] as String,
        image: image,
        rest: rest,
        uv: uv,
        indices: Uint16List.fromList(tris),
        weights: [
          for (final w in weights) [for (final pair in w.cast<List>()) ((pair[0] as num).toInt(), (pair[1] as num).toDouble())],
        ],
      ));
    }
    // Back to front: the long hair behind everything, both legs behind the
    // skirt, the head behind the collar, the near arm in front.
    // Each leg is one image bent at the knee, a patch over the knee that
    // fills the crease of a deep bend, and a rigid shoe over the shin's end.
    const order = [
      'hair_back', 'far_arm', 'far_leg', 'far_knee', 'far_shoe', 'near_leg', 'near_knee', 'near_shoe', //
      'skirt', 'head', 'head_front', 'body', 'near_arm',
    ];
    layers.sort((a, b) => order.indexOf(a.name).compareTo(order.indexOf(b.name)));
    final hats = <String, ui.Image>{};
    for (final (id, _) in girlHatUnlocks) {
      if (id == 'none') continue;
      final bytes = await rootBundle.load('${CompanionSprite.folder}/hat_$id.png');
      hats[id] = await decodeImageFromList(bytes.buffer.asUint8List());
    }
    return CompanionRig._(
      size[0].toDouble(),
      size[1].toDouble(),
      floor,
      Offset(crown[0].toDouble(), crown[1].toDouble()),
      sole,
      bones,
      layers,
      hats,
    );
  }

  int boneIndex(String name) => bones.indexWhere((b) => b.name == name);

  /// Canvas px per unit of the pose's 100-unit box.
  static const unit = 17.0;

  /// Where the root bones sit for a pose: the hips' place in the box, off
  /// the standing one.
  static Offset rootOffset(Pose pose) => Offset((pose.hip.dx - 50) * unit, (pose.hip.dy - 55) * unit);

  /// Where each bone's head ends up and how much it turned, for a pose.
  /// [headTurn] tilts the head (and the hair with it) on top of the pose.
  /// [ankles] gives the near and far leg an ankle to reach instead of the
  /// pose's angles, keyed by the thigh bone's name, in canvas px.
  List<BoneXf> solve(Pose pose, {double hairSway = 0, double headTurn = 0, double footFollow = 0.35, Map<String, Offset>? ankles}) {
    final out = List<BoneXf>.filled(bones.length, const BoneXf(Offset.zero, 0));
    final root = rootOffset(pose);
    final reach = <String, Offset>{};
    for (var i = 0; i < bones.length; i++) {
      final b = bones[i];
      final rest = b.tail - b.head;
      final restAngle = math.atan2(rest.dy, rest.dx);
      Offset? want = switch (b.name) {
        'spine' => dirOf(180 - pose.torso),
        'near_upper' => dirOf(pose.arm.upper),
        'near_lower' => dirOf(pose.arm.lower),
        'far_upper' => dirOf((pose.arm2 ?? pose.arm).upper),
        'far_lower' => dirOf((pose.arm2 ?? pose.arm).lower),
        'near_thigh' => reach['near_thigh'] ?? dirOf(pose.leg.upper),
        'near_shin' => reach['near_shin'] ?? dirOf(pose.leg.lower),
        'far_thigh' => reach['far_thigh'] ?? dirOf((pose.leg2 ?? pose.leg).upper),
        'far_shin' => reach['far_shin'] ?? dirOf((pose.leg2 ?? pose.leg).lower),
        _ => null,
      };
      if (ankles != null && ankles.containsKey(b.name) && i + 1 < bones.length) {
        // Two-bone reach: the knee goes to the forward side.
        final shin = bones[i + 1];
        final l1 = rest.distance;
        final l2 = (shin.tail - shin.head).distance;
        final hip = b.head + root;
        final v = ankles[b.name]! - hip;
        final d = v.distance.clamp((l1 - l2).abs() + 1, l1 + l2 - 1);
        final u = v / v.distance;
        final cosA = ((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0);
        final a = math.acos(cosA);
        Offset rot(double r) => Offset(u.dx * math.cos(r) - u.dy * math.sin(r), u.dx * math.sin(r) + u.dy * math.cos(r));
        final k1 = rot(a);
        final k2 = rot(-a);
        final knee = k1.dx > k2.dx ? k1 : k2;
        want = knee;
        reach[shin.name] = u * d - knee * l1;
      }
      final double turn;
      if (want != null) {
        var t = math.atan2(want.dy, want.dx) - restAngle;
        while (t > math.pi) {
          t -= 2 * math.pi;
        }
        while (t < -math.pi) {
          t += 2 * math.pi;
        }
        turn = t;
      } else if (b.name.startsWith('hair')) {
        // Hair trails the head and sways with the stride; the second bone
        // adds its own share so the ends swing wider than the roots.
        turn = out[b.parent].turn + hairSway;
      } else if (b.name == 'head') {
        turn = out[b.parent].turn + headTurn;
      } else if (b.name.endsWith('_foot')) {
        // The ankle gives: the foot takes only a share of the shin's turn,
        // staying near level as the leg swings and flat on the ground
        // while the shin rolls over it. Pointed toes take all of it.
        turn = out[b.parent].turn * footFollow;
      } else {
        // Hands keep their parent's turn.
        turn = b.parent >= 0 ? out[b.parent].turn : 0;
      }
      final head = b.parent >= 0 ? out[b.parent].apply(b.head, bones[b.parent]) : b.head + root;
      out[i] = BoneXf(head, turn);
    }
    return out;
  }
}

class RigBone {
  const RigBone({required this.name, required this.parent, required this.head, required this.tail});
  final String name;
  final int parent;
  final Offset head;
  final Offset tail;
}

class RigLayer {
  const RigLayer({
    required this.name,
    required this.image,
    required this.rest,
    required this.uv,
    required this.indices,
    required this.weights,
  });
  final String name;
  final ui.Image image;
  final Float32List rest;
  final Float32List uv;
  final Uint16List indices;
  final List<List<(int, double)>> weights;
}

/// A bone's posed head and rotation; maps a rest-pose point to its posed place.
class BoneXf {
  const BoneXf(this.head, this.turn);
  final Offset head;
  final double turn;

  Offset apply(Offset p, RigBone bone) {
    final d = p - bone.head;
    final c = math.cos(turn);
    final s = math.sin(turn);
    return Offset(head.dx + d.dx * c - d.dy * s, head.dy + d.dx * s + d.dy * c);
  }
}

/// Draws the rig in a pose at a given height, feet on the widget's bottom.
class CompanionRigView extends StatelessWidget {
  const CompanionRigView({
    super.key,
    required this.rig,
    required this.pose,
    required this.height,
    this.farTint,
    this.hairSway = 0,
    this.hat = 'none',
    this.ground = true,
    this.flight = 40,
    this.prop = RigProp.none,
    this.phase = 0,
    this.flow = false,
    this.headTurn = 0,
    this.faceFront = 0,
    this.footFollow = 0.35,
    this.gearColor = const Color(0xFF8A7F78),
    this.ink = const Color(0xFF3A3335),
  });

  final CompanionRig rig;
  final Pose pose;
  final double height;

  /// Extra turn of the hair bones, radians.
  final double hairSway;

  /// Colour laid over the far arm and leg so they sit behind.
  final Color? farTint;

  /// One of the ids in [girlHatUnlocks], or 'none'.
  final String hat;

  /// Keeps the lower foot on the floor line, so a bent leg lowers the hips
  /// instead of lifting the foot off the ground.
  final bool ground;

  /// How far (canvas px) the feet may float above the floor while they
  /// change over: small for a walk, larger for a run, which then has a
  /// moment in the air at each stride.
  final double flight;

  /// Equipment drawn with the figure: a bicycle with the pedals under the
  /// feet, a staircase the feet step up, a rowing machine or an elliptical.
  final RigProp prop;

  /// The cycle count the equipment moves with (the stairs pass by it).
  final double phase;

  /// In water: the skirt streams along the body instead of hanging down.
  final bool flow;

  /// Extra tilt of the head, radians; negative lifts the face.
  final double headTurn;

  /// How far the head is turned to face the viewer, 0 to 1: the profile
  /// fades into the front view of the face, as when a swimmer breathes.
  final double faceFront;

  /// How much of the shin's turn the foot takes: a little on land, so the
  /// shoe stays level with the ground; all of it in water, toes pointed.
  final double footFollow;

  /// Frames, saddles, rails and treads.
  final Color gearColor;

  /// Tyres, spokes, cables and edges.
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final width = height * rig.width / rig.height;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _RigPainter(this), willChange: true),
    );
  }
}

class _RigPainter extends CustomPainter {
  _RigPainter(this.v);
  final CompanionRigView v;
  CompanionRig get rig => v.rig;
  Pose get pose => v.pose;
  Color? get farTint => v.farTint;
  double get hairSway => v.hairSway;
  String get hat => v.hat;

  /// A point fixed to a bone in the rest pose, where it ends up.
  Offset _at(List<BoneXf> xf, int bone, Offset rest) => xf[bone].apply(rest, rig.bones[bone]);

  /// Middle of the sole of a foot, under the ball of the foot.
  Offset _ballOfFoot(List<BoneXf> xf, int foot) {
    final head = rig.bones[foot].head;
    var sum = Offset.zero;
    for (final s in rig.sole) {
      sum += _at(xf, foot, head + s);
    }
    return sum / rig.sole.length.toDouble();
  }

  /// Ankle targets for climbing: each foot's place on the staircase, from
  /// [climbFoot], less the sole's offset under the ankle, which depends on
  /// how the shin ends up turned, so it is solved twice.
  Map<String, Offset> _climbAnkles() {
    final root = CompanionRig.rootOffset(pose);
    final targets = <String, Offset>{};
    for (final (thigh, t) in [('near_thigh', v.phase), ('far_thigh', v.phase + 0.5)]) {
      final i = rig.boneIndex(thigh);
      if (i < 0) continue;
      final hip = rig.bones[i].head + root;
      targets[thigh] = hip + (climbFoot(t) - climbHip) * CompanionRig.unit;
    }
    var ankles = Map<String, Offset>.from(targets);
    final ball = rig.sole.reduce((a, b) => a + b) / rig.sole.length.toDouble();
    for (var pass = 0; pass < 2; pass++) {
      final xf = rig.solve(pose, hairSway: hairSway, headTurn: v.headTurn, footFollow: v.footFollow, ankles: ankles);
      ankles = {
        for (final e in targets.entries)
          e.key: () {
            final foot = rig.boneIndex(e.key.replaceFirst('thigh', 'foot'));
            final turn = foot >= 0 ? xf[foot].turn : 0.0;
            final c = math.cos(turn);
            final s = math.sin(turn);
            return e.value - Offset(ball.dx * c - ball.dy * s, ball.dx * s + ball.dy * c);
          }(),
      };
    }
    return ankles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / rig.height;
    final xf = rig.solve(
      pose,
      hairSway: hairSway,
      headTurn: v.headTurn,
      footFollow: v.footFollow,
      ankles: v.prop == RigProp.stairs ? _climbAnkles() : null,
    );
    final nearFoot = rig.boneIndex('near_foot');
    final farFoot = rig.boneIndex('far_foot');
    final feet = [if (nearFoot >= 0) nearFoot, if (farFoot >= 0) farFoot];
    // Where the drawing is lifted or lowered as a whole: onto the pedals
    // of the bicycle, the seat of the machine, or the lower foot onto the
    // floor line. On the stairs the hips stay put and the treads move.
    var shift = 0.0;
    Offset? crank;
    if (v.prop == RigProp.bike && feet.length == 2) {
      final pedals = [for (final f in feet) _ballOfFoot(xf, f)];
      crank = (pedals[0] + pedals[1]) / 2;
      shift = rig.floor - _wheelRadius + _crankDrop - crank.dy;
    } else if (v.prop == RigProp.rower) {
      shift = rig.floor - _rowerRail(xf) - rig.height * 0.03;
    } else if (v.prop == RigProp.elliptical && feet.length == 2) {
      final low = feet.map((f) => _ballOfFoot(xf, f).dy).reduce(math.max);
      shift = rig.floor - rig.height * 0.07 - low;
    } else if (v.prop == RigProp.stairs) {
      shift = 0;
    } else if (v.ground && feet.isNotEmpty) {
      // The lower foot, taken softly: while the feet change over the figure
      // floats a little rather than jolting from one leg to the other.
      final lows = <double>[];
      for (final f in feet) {
        final head = rig.bones[f].head;
        var low = double.negativeInfinity;
        for (final s in rig.sole) {
          low = math.max(low, _at(xf, f, head + s).dy);
        }
        lows.add(low);
      }
      final m = lows.reduce(math.max);
      final k = math.max(1.0, v.flight);
      var sum = 0.0;
      for (final y in lows) {
        sum += math.exp((y - m) / k);
      }
      shift = rig.floor - (m + k * math.log(sum));
    }
    // The skirt's front is weighted to the near thigh and its back to the
    // far one, but a skirt follows whichever leg is in front: the front hem
    // goes with the forward thigh and the back hem with the other, so
    // neither leg comes out from under it.
    final nearThigh = rig.bones.indexWhere((b) => b.name == 'near_thigh');
    final farThigh = rig.bones.indexWhere((b) => b.name == 'far_thigh');
    var swapThighs = false;
    if (nearThigh >= 0 && farThigh >= 0) {
      final nearKnee = xf[nearThigh].apply(rig.bones[nearThigh].tail, rig.bones[nearThigh]);
      final farKnee = xf[farThigh].apply(rig.bones[farThigh].tail, rig.bones[farThigh]);
      swapThighs = farKnee.dx > nearKnee.dx;
    }
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, shift);
    if (crank != null) _drawBike(canvas, xf, crank, [for (final f in feet) _ballOfFoot(xf, f)]);
    if (v.prop == RigProp.stairs && feet.length == 2) _drawStairs(canvas, xf, feet);
    if (v.prop == RigProp.rower) _drawRower(canvas, xf, feet);
    if (v.prop == RigProp.elliptical && feet.length == 2) _drawElliptical(canvas, xf, feet);
    final spine = rig.boneIndex('spine');
    final spineTurn = spine >= 0 ? xf[spine].turn : 0.0;
    for (final layer in rig.layers) {
      final n = layer.rest.length ~/ 2;
      final pos = Float32List(n * 2);
      final swap = swapThighs && layer.name == 'skirt';
      for (var i = 0; i < n; i++) {
        final p = Offset(layer.rest[i * 2], layer.rest[i * 2 + 1]);
        var x = 0.0;
        var y = 0.0;
        for (final (bone, w) in layer.weights[i]) {
          final b = !swap
              ? bone
              : bone == nearThigh
              ? farThigh
              : bone == farThigh
              ? nearThigh
              : bone;
          final thigh = b == nearThigh || b == farThigh;
          final forward = swapThighs ? b == farThigh : b == nearThigh;
          final q = thigh && layer.name == 'skirt'
              ? _skirtSwing(xf[b], rig.bones[b], p, forward ? 0.5 : 0.25, v.flow ? spineTurn : 0)
              : xf[b].apply(p, rig.bones[b]);
          x += q.dx * w;
          y += q.dy * w;
        }
        pos[i * 2] = x;
        pos[i * 2 + 1] = y;
      }
      final alpha = switch (layer.name) {
        'head' => 1 - v.faceFront,
        'head_front' => v.faceFront,
        _ => 1.0,
      };
      if (alpha <= 0) continue;
      final verts = ui.Vertices.raw(VertexMode.triangles, pos, textureCoordinates: layer.uv, indices: layer.indices);
      final paint = Paint()
        ..shader = ImageShader(layer.image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage)
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0))
        ..filterQuality = FilterQuality.medium;
      if (farTint != null && layer.name.startsWith('far')) {
        paint.colorFilter = ColorFilter.mode(farTint!, BlendMode.srcATop);
      }
      canvas.drawVertices(verts, BlendMode.srcOver, paint);
    }
    _drawHat(canvas, xf);
    canvas.restore();
  }

  /// How a thigh carries the skirt: the panel in front of it swings from the
  /// waist like a pendulum, by half the thigh's angle, so the hem rides up
  /// over a raised knee; the panel behind the other leg trails by a quarter.
  /// [base] is the angle the skirt hangs at before the thighs push it: down,
  /// or along the body when it streams in water.
  Offset _skirtSwing(BoneXf x, RigBone bone, Offset p, double share, double base) {
    final lift = rig.height * 0.068;
    final pivotRest = bone.head - Offset(0, lift);
    final pivotPosed = x.head - Offset(0, lift);
    final d = p - pivotRest;
    final angle = base + (x.turn - base) * share;
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Offset(pivotPosed.dx + d.dx * c - d.dy * s, pivotPosed.dy + d.dx * s + d.dy * c);
  }

  /// The staircase the feet climb: the tread under the foot that is
  /// standing, and the rest at the same pitch up and down from it, over a
  /// filled bank. Treads pass at two a cycle, so the foot rides its tread.
  void _drawStairs(Canvas canvas, List<BoneXf> xf, List<int> feet) {
    final h = rig.height;
    final u = v.phase % 1;
    // The near foot stands for the first six tenths of the cycle. The tread
    // is put where the foot is meant to be rather than where the leg
    // reached, so the staircase never jumps when the standing foot changes.
    final near = u < climbStance;
    final thigh = rig.boneIndex(near ? 'near_thigh' : 'far_thigh');
    final hip = (thigh >= 0 ? rig.bones[thigh].head : Offset(rig.width / 2, rig.height / 2)) + CompanionRig.rootOffset(pose);
    final sole = hip + (climbFoot(near ? v.phase : v.phase + 0.5) - climbHip) * CompanionRig.unit;
    final run = climbRun * CompanionRig.unit;
    final rise = climbRise * CompanionRig.unit;
    final nose = Offset(sole.dx + run * 0.35, sole.dy);
    final top = Paint()..color = Color.lerp(v.gearColor, const Color(0xFFFFFFFF), 0.35)!;
    final face = Paint()..color = v.gearColor;
    final edge = Paint()
      ..color = v.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.004;
    // The bank under the steps, then each step.
    final bank = Path()..moveTo(nose.dx - 16 * run, h * 3);
    for (var k = -16; k <= 16; k++) {
      final x = nose.dx + k * run;
      final y = nose.dy - k * rise;
      bank.lineTo(x - run, y);
      bank.lineTo(x, y);
    }
    bank.lineTo(nose.dx + 16 * run, h * 3);
    bank.close();
    canvas.drawPath(bank, face);
    for (var k = -16; k <= 16; k++) {
      final x = nose.dx + k * run;
      final y = nose.dy - k * rise;
      canvas.drawRect(Rect.fromLTWH(x - run, y, run, h * 0.012), top);
      canvas.drawLine(Offset(x - run, y), Offset(x, y), edge);
      // The riser climbs from this tread's nose to the next tread.
      canvas.drawLine(Offset(x, y), Offset(x, y - rise), edge);
    }
  }

  /// The rail of the rowing machine: just under the seat, which is under
  /// the hips.
  double _rowerRail(List<BoneXf> xf) {
    final thigh = rig.boneIndex('near_thigh');
    final hip = thigh >= 0 ? xf[thigh].head : Offset(rig.width / 2, rig.height / 2);
    return hip.dy + rig.height * 0.06;
  }

  /// A rowing machine: a rail on the floor, the seat under the hips sliding
  /// on it, the footplate under the feet, and the handle in the hands on a
  /// cord to the flywheel at the front.
  void _drawRower(Canvas canvas, List<BoneXf> xf, List<int> feet) {
    final h = rig.height;
    final thigh = rig.boneIndex('near_thigh');
    final hand = rig.boneIndex('near_hand');
    final hip = thigh >= 0 ? xf[thigh].head : Offset(rig.width / 2, rig.height / 2);
    final rail = _rowerRail(xf);
    final foot = feet.isEmpty ? hip + Offset(h * 0.3, h * 0.2) : _ballOfFoot(xf, feet.first);
    final grip = hand >= 0 ? _at(xf, hand, rig.bones[hand].tail) : hip + Offset(h * 0.2, -h * 0.1);
    final frame = Paint()
      ..color = v.gearColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.012
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = v.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.004
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = v.gearColor;
    final wheel = Offset(foot.dx + h * 0.16, rail - h * 0.08);
    canvas.drawLine(Offset(hip.dx - h * 0.28, rail), Offset(wheel.dx, rail), frame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hip.dx - h * 0.02, rail - h * 0.02), width: h * 0.09, height: h * 0.026), Radius.circular(h * 0.01)),
      fill,
    );
    // Footplate at the feet, leaning back.
    canvas.drawLine(foot + Offset(-h * 0.02, h * 0.035), foot + Offset(h * 0.03, -h * 0.05), frame);
    canvas.drawLine(foot + Offset(-h * 0.01, h * 0.03), Offset(foot.dx, rail), thin);
    // Flywheel housing and the cord to the handle.
    canvas.drawCircle(wheel, h * 0.075, fill);
    canvas.drawCircle(wheel, h * 0.075, thin);
    canvas.drawCircle(wheel, h * 0.02, Paint()..color = v.ink);
    canvas.drawLine(wheel, Offset(wheel.dx, rail), frame);
    canvas.drawLine(Offset(wheel.dx - h * 0.075, wheel.dy - h * 0.02), grip, thin);
    canvas.drawLine(grip + Offset(h * 0.01, -h * 0.03), grip + Offset(h * 0.01, h * 0.03), frame);
  }

  /// An elliptical: pedals under the feet on arms from a hub at the back,
  /// a post in front with the handles at the hand, on a base on the floor.
  void _drawElliptical(Canvas canvas, List<BoneXf> xf, List<int> feet) {
    final h = rig.height;
    final hand = rig.boneIndex('near_hand');
    final pedals = [for (final f in feet) _ballOfFoot(xf, f)];
    final low = pedals.map((p) => p.dy).reduce(math.max);
    final base = low + h * 0.07;
    final back = Offset(pedals.map((p) => p.dx).reduce(math.min) - h * 0.12, base - h * 0.08);
    final grip = hand >= 0 ? _at(xf, hand, rig.bones[hand].tail) : back + Offset(h * 0.4, -h * 0.4);
    final frame = Paint()
      ..color = v.gearColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.012
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = v.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.004
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = v.gearColor;
    final postX = pedals.map((p) => p.dx).reduce(math.max) + h * 0.14;
    canvas.drawLine(Offset(back.dx - h * 0.03, base), Offset(postX + h * 0.05, base), frame);
    canvas.drawCircle(back, h * 0.06, fill);
    canvas.drawCircle(back, h * 0.06, thin);
    for (final p in pedals) {
      canvas.drawLine(back, p + Offset(0, h * 0.01), thin);
      canvas.drawLine(p + Offset(-h * 0.035, h * 0.012), p + Offset(h * 0.04, h * 0.012), frame);
    }
    canvas.drawLine(Offset(postX, base), Offset(postX, grip.dy - h * 0.02), frame);
    canvas.drawLine(Offset(postX, grip.dy + h * 0.02), grip + Offset(-h * 0.01, 0), thin);
    canvas.drawLine(grip + Offset(-h * 0.01, h * 0.03), grip + Offset(-h * 0.01, -h * 0.05), frame);
  }

  double get _wheelRadius => rig.height * 0.17;

  /// How far the crank sits below the hubs.
  double get _crankDrop => rig.height * 0.03;

  /// A bicycle drawn behind the figure: the crank between the feet, the
  /// wheels on the floor, the saddle under the hips and the bars at the
  /// near hand. The wheels turn with the crank.
  void _drawBike(Canvas canvas, List<BoneXf> xf, Offset crank, List<Offset> pedals) {
    final h = rig.height;
    final r = _wheelRadius;
    final hubY = crank.dy - _crankDrop;
    final rear = Offset(crank.dx - h * 0.2, hubY);
    final front = Offset(crank.dx + h * 0.29, hubY);
    final thigh = rig.boneIndex('near_thigh');
    final hand = rig.boneIndex('near_hand');
    final saddle = (thigh >= 0 ? xf[thigh].head : crank - Offset(0, h * 0.3)) + Offset(-h * 0.035, h * 0.03);
    final grip = (hand >= 0 ? _at(xf, hand, rig.bones[hand].tail) : crank + Offset(h * 0.25, -h * 0.25)) + Offset(h * 0.012, h * 0.008);
    final head = Offset(front.dx - h * 0.03, grip.dy + h * 0.03);
    final tyre = Paint()
      ..color = v.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.009
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = v.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.004
      ..strokeCap = StrokeCap.round;
    final frame = Paint()
      ..color = v.gearColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.011
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final spin = math.atan2(pedals[0].dy - crank.dy, pedals[0].dx - crank.dx) * 2.6;
    for (final hub in [rear, front]) {
      canvas.drawCircle(hub, r, tyre);
      canvas.drawCircle(hub, r - h * 0.012, thin);
      for (var i = 0; i < 8; i++) {
        final a = spin + i * math.pi / 4;
        canvas.drawLine(hub, hub + Offset(math.cos(a), math.sin(a)) * (r - h * 0.012), thin);
      }
      canvas.drawCircle(hub, h * 0.012, Paint()..color = v.ink);
    }
    // Chain from the ring at the crank to the cog at the rear hub.
    final ring = h * 0.045;
    final cog = h * 0.018;
    canvas.drawCircle(crank, ring, thin);
    canvas.drawLine(Offset(crank.dx, crank.dy - ring), Offset(rear.dx, rear.dy - cog), thin);
    canvas.drawLine(Offset(crank.dx, crank.dy + ring), Offset(rear.dx, rear.dy + cog), thin);
    canvas.drawPath(Path()..addPolygon([rear, crank, saddle], true), frame);
    canvas.drawPath(Path()..addPolygon([saddle, head, crank], true), frame);
    canvas.drawLine(head, front, frame);
    canvas.drawLine(head, grip + Offset(-h * 0.01, 0), frame);
    canvas.drawLine(grip + Offset(-h * 0.03, h * 0.004), grip + Offset(h * 0.035, -h * 0.01), frame);
    canvas.drawOval(Rect.fromCenter(center: saddle, width: h * 0.08, height: h * 0.024), Paint()..color = v.gearColor);
    for (final p in pedals) {
      canvas.drawLine(crank, p, tyre);
      canvas.drawLine(p + Offset(-h * 0.025, 0), p + Offset(h * 0.025, 0), tyre);
    }
  }

  /// The hat rides on the crown, turning with the head. Sizes and offsets
  /// are the fractions of the figure's height used on the single drawings,
  /// scaled down because this figure's head is three quarters the size.
  void _drawHat(Canvas canvas, List<BoneXf> xf) {
    final image = rig.hats[hat];
    if (image == null) return;
    final h = rig.height * 0.75;
    final (double w, double dx, double dy) = switch (hat) {
      'cap' => (h * 0.21, h * 0.015, -h * 0.03),
      'beanie' => (h * 0.17, h * 0.005, -h * 0.045),
      'flower' => (h * 0.21, h * 0.005, h * 0.01),
      'headphones' => (h * 0.19, h * 0.005, h * 0.015),
      'ribbon' => (h * 0.085, -h * 0.06, h * 0.045),
      'glasses' => (h * 0.14, h * 0.03, h * 0.085),
      _ => (0.0, 0.0, 0.0),
    };
    if (w <= 0) return;
    final head = rig.bones.indexWhere((b) => b.name == 'head');
    if (head < 0) return;
    final at = xf[head].apply(rig.crown, rig.bones[head]);
    final ih = w * image.height / image.width;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(xf[head].turn);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(dx - w / 2, dy, w, ih),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RigPainter old) =>
      old.pose != pose ||
      old.rig != rig ||
      old.hairSway != hairSway ||
      old.hat != hat ||
      old.v.ground != v.ground ||
      old.v.flight != v.flight ||
      old.v.prop != v.prop ||
      old.v.phase != v.phase ||
      old.v.flow != v.flow ||
      old.v.headTurn != v.headTurn ||
      old.v.faceFront != v.faceFront ||
      old.v.footFollow != v.footFollow ||
      old.v.gearColor != v.gearColor;
}
