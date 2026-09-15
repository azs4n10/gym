import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym/data/exercise_moves.dart';
import 'package:gym/models/enums.dart';
import 'package:gym/state/app_state.dart';
import 'package:gym/theme/app_theme.dart';
import 'package:gym/widgets/exercise_figure.dart';
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
    final kinds = [
      for (final k in CardioType.values)
        if (cardioMoves[k]?.loops ?? false)
          if (only == null || only.isEmpty || only.split(',').contains(k.name)) k,
    ];
    const frames = 8;
    const size = 96.0;
    final key = GlobalKey();

    await tester.binding.setSurfaceSize(Size(frames * size + 16, kinds.length * (size + 20) + 16));
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
                    for (final k in kinds) ...[
                      Text(k.name, style: const TextStyle(fontSize: 11)),
                      Row(
                        children: [
                          for (var i = 0; i < frames; i++)
                            ExerciseFigure(move: cardioMoves[k]!, size: size, t: i / frames),
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
    expect(find.byType(ExerciseFigure), findsNWidgets(kinds.length * frames));

    final out = Platform.environment['PREVIEW_OUT'];
    if (out == null || out.isEmpty) return;
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
