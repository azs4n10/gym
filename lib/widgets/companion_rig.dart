import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/run_play.dart';
import 'companion_sprite.dart';
import 'exercise_figure.dart';

/// A cut-out rig of the illustrated companion: the drawing split into a few
/// layers, each a small triangle mesh whose vertices follow the bones with
/// blended weights (built by tool scripts into assets/companion/rig). The
/// bones take their angles from the same [Pose] the stick figure uses, so
/// every cycle the app already has plays on the illustration, smoothly.
class CompanionRig {
  CompanionRig._(this.width, this.height, this.crown, this.bones, this.layers, this.hats);

  final double width;
  final double height;

  /// Top of the head in the rest pose, where hats sit.
  final Offset crown;
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
    const order = ['hair_back', 'far_arm', 'far_leg', 'near_leg', 'skirt', 'head', 'body', 'near_arm'];
    layers.sort((a, b) => order.indexOf(a.name).compareTo(order.indexOf(b.name)));
    final hats = <String, ui.Image>{};
    for (final (id, _) in girlHatUnlocks) {
      if (id == 'none') continue;
      final bytes = await rootBundle.load('${CompanionSprite.folder}/hat_$id.png');
      hats[id] = await decodeImageFromList(bytes.buffer.asUint8List());
    }
    return CompanionRig._(size[0].toDouble(), size[1].toDouble(), Offset(crown[0].toDouble(), crown[1].toDouble()), bones, layers, hats);
  }

  /// Where each bone's head ends up and how much it turned, for a pose.
  List<BoneXf> solve(Pose pose, {double unit = 17, double hairSway = 0}) {
    final out = List<BoneXf>.filled(bones.length, const BoneXf(Offset.zero, 0));
    final root = Offset(0, (pose.hip.dy - 55) * unit);
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
        'near_thigh' => dirOf(pose.leg.upper),
        'near_shin' => dirOf(pose.leg.lower),
        'far_thigh' => dirOf((pose.leg2 ?? pose.leg).upper),
        'far_shin' => dirOf((pose.leg2 ?? pose.leg).lower),
        _ => null,
      };
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
      } else {
        // Head, hands and feet keep their parent's turn.
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

  @override
  Widget build(BuildContext context) {
    final width = height * rig.width / rig.height;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _RigPainter(rig, pose, farTint, hairSway, hat), willChange: true),
    );
  }
}

class _RigPainter extends CustomPainter {
  _RigPainter(this.rig, this.pose, this.farTint, this.hairSway, this.hat);
  final CompanionRig rig;
  final Pose pose;
  final Color? farTint;
  final double hairSway;
  final String hat;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / rig.height;
    final xf = rig.solve(pose, hairSway: hairSway);
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
          final q = xf[b].apply(p, rig.bones[b]);
          x += q.dx * w;
          y += q.dy * w;
        }
        pos[i * 2] = x;
        pos[i * 2 + 1] = y;
      }
      final verts = ui.Vertices.raw(VertexMode.triangles, pos, textureCoordinates: layer.uv, indices: layer.indices);
      final paint = Paint()
        ..shader = ImageShader(layer.image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage)
        ..filterQuality = FilterQuality.medium;
      if (farTint != null && layer.name.startsWith('far')) {
        paint.colorFilter = ColorFilter.mode(farTint!, BlendMode.srcATop);
      }
      canvas.drawVertices(verts, BlendMode.srcOver, paint);
    }
    _drawHat(canvas, xf);
    canvas.restore();
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
  bool shouldRepaint(_RigPainter old) => old.pose != pose || old.rig != rig || old.hairSway != hairSway || old.hat != hat;
}
