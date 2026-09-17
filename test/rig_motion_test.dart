import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gym/data/exercise_moves.dart';
import 'package:gym/models/enums.dart';
import 'package:gym/models/run_play.dart';
import 'package:gym/widgets/companion_rig.dart';

/// The rigged figure must move smoothly through a cycle: no layer may jump
/// between two neighbouring phases by much more than it moves elsewhere.
/// With MOTION_OUT set, the per-phase movement of every layer is written
/// there for a closer look.
void main() {
  testWidgets('the rigged cycles have no jumps', (tester) async {
    final rig = (await tester.runAsync(() => CompanionRig.side()))!;
    final out = Platform.environment['MOTION_OUT'];
    final report = StringBuffer();
    const steps = 240;
    for (final kind in [CardioType.running, CardioType.walking, CardioType.stairs, CardioType.cycling]) {
      final move = cardioMoves[kind]!;
      final contact = rigPropFor(kind) == RigProp.none ? ContactCurve.fit(rig, move) : null;
      List<double>? last;
      final worst = <String, double>{};
      final typical = <String, List<double>>{};
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final view = CompanionRigView(
          rig: rig,
          pose: move.at(t % 1),
          height: 1460,
          hairSway: 0.09 * math.sin(4 * math.pi * t - 1.4),
          ground: contact != null,
          prop: rigPropFor(kind),
          phase: t,
          groundDepth: contact?.depth(t % 1),
          bounce: 1,
        );
        final placed = view.place();
        final flat = <double>[];
        for (var li = 0; li < rig.layers.length; li++) {
          final pos = placed.positions[li];
          var sx = 0.0;
          var sy = 0.0;
          final n = pos.length ~/ 2;
          for (var k = 0; k < n; k++) {
            sx += pos[k * 2];
            sy += pos[k * 2 + 1] + placed.shift;
          }
          flat.add(sx / n);
          flat.add(sy / n);
        }
        if (last != null) {
          for (var li = 0; li < rig.layers.length; li++) {
            final name = rig.layers[li].name;
            final d = (Offset(flat[li * 2], flat[li * 2 + 1]) - Offset(last[li * 2], last[li * 2 + 1])).distance;
            typical.putIfAbsent(name, () => []).add(d);
            if (d > (worst[name] ?? 0)) {
              worst[name] = d;
              report.writeln('${kind.name} ${name.padRight(10)} step $i: ${d.toStringAsFixed(1)} px');
            }
          }
        }
        last = flat;
      }
      for (final name in typical.keys) {
        final ds = typical[name]!..sort();
        final median = ds[ds.length ~/ 2];
        final max = ds.last;
        report.writeln('${kind.name} ${name.padRight(10)} median ${median.toStringAsFixed(1)} max ${max.toStringAsFixed(1)} ratio ${(max / math.max(median, 0.1)).toStringAsFixed(1)}');
        // The knee patch and hair may legitimately move faster at moments;
        // a body layer jumping ten times its usual step is a pop.
        expect(max, lessThan(math.max(median * 10, 12)), reason: '$kind $name jumps at some phase');
      }
    }
    if (out != null && out.isNotEmpty) File(out).writeAsStringSync(report.toString());
  });
}
