import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym/data/database.dart';
import 'package:gym/screens/workout/run_screen.dart';
import 'package:gym/state/app_state.dart';
import 'package:gym/state/body_state.dart';
import 'package:gym/state/workout_state.dart';
import 'package:gym/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the run clock and distance follow the set speed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.create();
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<BodyState>(create: (_) => BodyState(db)),
          ChangeNotifierProvider<WorkoutState>(create: (_) => WorkoutState(db)),
        ],
        child: MaterialApp(
          theme: buildTheme(app.skin, font: app.profile.font),
          home: const RunScreen(),
        ),
      ),
    );
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
  });
}
