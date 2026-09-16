import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym/data/exercise_moves.dart';
import 'package:gym/models/enums.dart';
import 'package:gym/models/run_play.dart';
import 'package:gym/state/app_state.dart';
import 'package:gym/theme/app_theme.dart';
import 'package:gym/widgets/companion_rig.dart';
import 'package:gym/widgets/companion_sprite.dart';
import 'package:gym/widgets/exercise_figure.dart';
import 'package:gym/widgets/run_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Draws a row of frames for the cardio cycles named in PREVIEW_ONLY (comma
/// separated; all of them when unset) and writes the sheet to PREVIEW_OUT.
/// Without PREVIEW_OUT it only checks that the figures render.
void main() {
  testWidgets('cardio cycles render as a contact sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.create();
    final only = Platform.environment['PREVIEW_ONLY'];
    final rest = only == 'rest';
    final back = only == 'back';
    final girl = only == 'girl';
    if (only == 'scene') {
      // The scene card as the run screen lays it out: the world, the rigged
      // figure and, for swimming, the water in front of her.
      final rig = await tester.runAsync(() => CompanionRig.side());
      final kind = CardioType.values.byName(Platform.environment['PREVIEW_KIND'] ?? 'running');
      final move = cardioMoves[kind]!;
      final skin = app.skin;
      const n = 4;
      const w = 360.0;
      const h = 240.0;
      final rkey = GlobalKey();
      await tester.binding.setSurfaceSize(Size(n * (w + 8) + 16, h + 16));
      final swim = kind == CardioType.swimming;
      final rigH = 176 * 1.02;
      final rigW = rigH * rig!.width / rig.height;
      await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
          key: rkey,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: RunScene(
                                route: runRoutes.first,
                                km: 0.9 + i * 0.05,
                                seconds: i * 0.7,
                                view: SceneView.side,
                                weather: SceneWeather.clear,
                                incline: 0,
                                now: DateTime(2026, 9, 16, 10 + i * 3),
                                skin: skin,
                                ja: false,
                                labelStyle: const TextStyle(fontSize: 11),
                                water: swim,
                              ),
                            ),
                            Positioned(
                              left: w * RunScene.runnerX - rigW / 2,
                              top: swim ? h * RunScene.waterY - rigH * 0.36 : h * RunScene.groundY - rigH * 0.99,
                              child: CompanionRigView(
                                rig: rig,
                                pose: move.at(i / n),
                                height: rigH,
                                farTint: skin.ink.withValues(alpha: 0.08),
                                hairSway: 0.05 * math.sin(4 * math.pi * i / n - 1.4),
                                ground: !swim && kind != CardioType.cycling,
                                bike: kind == CardioType.cycling,
                                gearColor: skin.button,
                                ink: skin.ink,
                              ),
                            ),
                            if (swim)
                              Positioned.fill(
                                child: CustomPaint(painter: WaterOverlay(skin: skin, seconds: i * 0.7, km: 0.9, swimmerX: RunScene.runnerX)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      final out = Platform.environment['PREVIEW_OUT'];
      if (out != null && out.isNotEmpty) {
        final boundary = rkey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
      }
      return;
    }
    if (only == 'rig') {
      final rig = await tester.runAsync(() => CompanionRig.side());
      final kind = CardioType.values.byName(Platform.environment['PREVIEW_KIND'] ?? 'running');
      final move = cardioMoves[kind]!;
      final n = int.tryParse(Platform.environment['PREVIEW_N'] ?? '') ?? 8;
      final h = double.tryParse(Platform.environment['PREVIEW_H'] ?? '') ?? 300.0;
      final rkey = GlobalKey();
      await tester.binding.setSurfaceSize(Size(n * (h / 2) + 16, h + 36));
      await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
          key: rkey,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  for (var i = 0; i < n; i++)
                    SizedBox(
                      width: h / 2,
                      height: h + 20,
                      child: Center(
                        child: CompanionRigView(
                          rig: rig!,
                          pose: move.at(i / n),
                          height: h,
                          farTint: const Color(0x20000000),
                          hairSway: 0.09 * math.sin(4 * math.pi * i / n - 1.4),
                          hat: const ['none', 'cap', 'beanie', 'flower', 'headphones', 'ribbon', 'glasses', 'none'][i % 8],
                          ground: kind != CardioType.cycling && kind != CardioType.swimming,
                          flight: kind == CardioType.running ? 120 : 40,
                          bike: kind == CardioType.cycling,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      final out = Platform.environment['PREVIEW_OUT'];
      if (out != null && out.isNotEmpty) {
        final boundary = rkey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
      }
      return;
    }
    const girlFrames = ['run_side_a', 'run_side_b', 'run_side_c', 'run_side_d', 'sit_side', 'run_back_a', 'stand_back', 'stand_front'];
    const girlHats = ['none', 'cap', 'beanie', 'flower', 'headphones', 'ribbon'];
    final moves = <(String, Move)>[
      if (rest) ('sit', sitMove),
      if (rest) ('standBack', standBackMove),
      if (back)
        for (final k in [CardioType.running, CardioType.walking, CardioType.cycling, CardioType.hiit])
          ('${k.name}Back', backMoveFor(k)),
      if (!rest && !back)
        for (final k in CardioType.values)
          if (cardioMoves[k]?.loops ?? false)
            if (only == null || only.isEmpty || only.split(',').contains(k.name)) (k.name, cardioMoves[k]!),
    ];
    const frames = 8;
    const size = 96.0;
    final key = GlobalKey();

    if (girl) {
      await tester.binding.setSurfaceSize(Size(girlHats.length * 130.0 + 16, girlFrames.length * 190.0 + 16));
      final gkey = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
          key: gkey,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final f in girlFrames)
                    Row(
                      children: [
                        for (final h in girlHats)
                          SizedBox(width: 130, height: 190, child: Center(child: DressedPose(frame: f, height: 176, hat: h, back: f.contains('back')))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
      final out = Platform.environment['PREVIEW_OUT'];
      if (out != null && out.isNotEmpty) {
        final boundary = gkey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
      }
      return;
    }
    await tester.binding.setSurfaceSize(Size(frames * size + 16, moves.length * (size + 20) + 16));
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<AppState>.value(value: app)],
        child: MaterialApp(
          theme: buildTheme(app.skin, font: app.profile.font),
          home: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (name, move) in moves) ...[
                      Text(name, style: const TextStyle(fontSize: 11)),
                      Row(
                        children: [
                          for (var i = 0; i < frames; i++)
                            ExerciseFigure(
                              move: move,
                              size: size,
                              t: move.loops ? i / frames : 1 - (2 * (i / frames) - 1).abs(),
                              face: rest ? FigureFace.rest : FigureFace.none,
                              hat: rest ? FigureHat.values[i % FigureHat.values.length] : FigureHat.none,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ExerciseFigure), findsNWidgets(moves.length * frames));

    final out = Platform.environment['PREVIEW_OUT'];
    if (out == null || out.isEmpty) return;
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
