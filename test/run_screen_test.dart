import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym/data/database.dart';
import 'package:gym/screens/workout/run_screen.dart';
import 'package:gym/widgets/companion_rig.dart';
import 'package:gym/state/app_state.dart';
import 'package:gym/state/body_state.dart';
import 'package:gym/state/workout_state.dart';
import 'package:gym/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the run clock and distance follow the set speed', timeout: const Timeout(Duration(seconds: 90)), (tester) async {
    final marks = Platform.environment['PREVIEW_MARKS'];
    void mark(String m) {
      if (marks != null && marks.isNotEmpty) File(marks).writeAsStringSync('$m\n', mode: FileMode.append);
    }
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.create();
    final db = AppDatabase(NativeDatabase.memory());
    // A phone-sized screen, with the rig loaded so the illustrated figure
    // shows in the screenshot (written to PREVIEW_OUT when set).
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final rig = await tester.runAsync(() => CompanionRig.side());
    mark('rig layers ${rig?.layers.length}');
    final shot = GlobalKey();

    // Pumped under runAsync so that the rig, loaded above, reaches the
    // screen: the future's callbacks run in that zone, not the test's.
    await tester.runAsync(() => tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<BodyState>(create: (_) => BodyState(db)),
          ChangeNotifierProvider<WorkoutState>(create: (_) => WorkoutState(db)),
        ],
        child: MaterialApp(
          theme: buildTheme(app.skin, font: app.profile.font),
          home: RepaintBoundary(key: shot, child: const RunScreen()),
        ),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('0.00 km'), findsOneWidget);

    tester.widget<Slider>(find.byType(Slider)).onChanged!(12);
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();

    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('0.10 km'), findsOneWidget);
    expect(find.text("5'00\""), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    mark('rig views ${find.byType(CompanionRigView).evaluate().length}');
    expect(find.byType(CompanionRigView), findsOneWidget);

    final out = Platform.environment['PREVIEW_OUT'];
    if (out != null && out.isNotEmpty) {
      final boundary = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    // Finish asks first; cancelling carries on, saving clears the screen
    // for the next outing. (No pumpAndSettle: the ticker never settles.)
    mark('finish');
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("Finish and save to today's workout?"), findsOneWidget);
    mark('dialog shown');
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pause'), findsOneWidget);
    mark('cancelled');
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    // Saving writes to the database, which is real asynchronous work.
    mark('second dialog');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      mark('save tapped');
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump(const Duration(milliseconds: 400));
    mark('saved');
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text("Saved to today's workout"), findsOneWidget);
  });
}
