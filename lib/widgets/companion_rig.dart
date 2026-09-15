import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exercise_figure.dart';

/// A cut-out rig of the illustrated companion: the drawing split into a few
/// layers, each a small triangle mesh whose vertices follow the bones with
/// blended weights (built by tool scripts into assets/companion/rig). The
/// bones take their angles from the same [Pose] the stick figure uses, so
/// every cycle the app already has plays on the illustration, smoothly.
class CompanionRig {
  CompanionRig._(this.width, this.height, this.bones, this.layers);

  final double width;
  final double height;
  final List<RigBone> bones;
  final List<RigLayer> layers;

  static Future<CompanionRig>? _side;

  /// The side-view rig, loaded once.
  static Future<CompanionRig> side() => _side ??= _load('assets/companion/rig/side.json');

  static Future<CompanionRig> _load(String path) async {
    final json = jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
    final dir = path.substring(0, path.lastIndexOf('/'));
    final size = (json['size'] as List).cast<num>();
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
    for (final l in (json['layers'] as List).cast<Map<String, dynamic>>()) {
      final bytes = await rootBundle.load('$dir/${l['image']}');
      final image = await decodeImageFromList(bytes.buffer.asUint8List());
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
    layers.sort((a, b) => a.name.compareTo(b.name));
    // Far to near, with both legs behind the body so the skirt covers the
    // thighs; the near arm hangs in front.
    const order = ['far_arm', 'far_leg', 'near_leg', 'body', 'near_arm'];
    layers.sort((a, b) => order.indexOf(a.name).compareTo(order.indexOf(b.name)));
    return CompanionRig._(size[0].toDouble(), size[1].toDouble(), bones, layers);
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
        // The far arm is drawn behind the body, so a full swing would only
        // show as stray pieces poking out; it swings gently instead.
        turn = b.name.startsWith('far_') && b.name.contains('upper') || b.name == 'far_lower' ? t * 0.35 : t;
      } else if (b.name == 'hair') {
        // Hair trails the head and sways with the stride.
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
  const CompanionRigView({super.key, required this.rig, required this.pose, required this.height, this.farTint, this.hairSway = 0});

  final CompanionRig rig;
  final Pose pose;
  final double height;

  /// Extra turn of the hair bone, radians.
  final double hairSway;

  /// Colour laid over the far arm and leg so they sit behind.
  final Color? farTint;

  @override
  Widget build(BuildContext context) {
    final width = height * rig.width / rig.height;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _RigPainter(rig, pose, farTint, hairSway), willChange: true),
    );
  }
}

class _RigPainter extends CustomPainter {
  _RigPainter(this.rig, this.pose, this.farTint, this.hairSway);
  final CompanionRig rig;
  final Pose pose;
  final Color? farTint;
  final double hairSway;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / rig.height;
    final xf = rig.solve(pose, hairSway: hairSway);
    canvas.save();
    canvas.scale(scale);
    for (final layer in rig.layers) {
      final n = layer.rest.length ~/ 2;
      final pos = Float32List(n * 2);
      for (var i = 0; i < n; i++) {
        final p = Offset(layer.rest[i * 2], layer.rest[i * 2 + 1]);
        var x = 0.0;
        var y = 0.0;
        for (final (b, w) in layer.weights[i]) {
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RigPainter old) => old.pose != pose || old.rig != rig || old.hairSway != hairSway;
}
