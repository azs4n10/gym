import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/connection.dart';
import 'data/database.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'state/body_state.dart';
import 'state/meal_state.dart';
import 'state/workout_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([initializeDateFormatting('en'), initializeDateFormatting('ja')]);

  final db = AppDatabase(openConnection());
  final app = await AppState.create();
  await _preloadFonts(app.profile.font);
  final workout = WorkoutState(db);
  final body = BodyState(db);
  final meal = MealState(db);
  await Future.wait([workout.load(), body.load(), meal.load()]);

  runApp(GymApp(app: app, workout: workout, body: body, meal: meal));
}

// Bold weights arrive as separate font files; lay out with them from the start
// so chips and labels are not measured with the regular weight first.
Future<void> _preloadFonts(String font) async {
  final rounded = font == 'rounded';
  TextStyle style({FontWeight? w}) => rounded
      ? GoogleFonts.mPlusRounded1c(fontWeight: w)
      : GoogleFonts.notoSansJp(fontWeight: w);
  final pending = GoogleFonts.pendingFonts([
    style(),
    style(w: FontWeight.w600),
    style(w: FontWeight.w700),
    style(w: FontWeight.w800),
  ]);
  await Future.any([pending, Future<void>.delayed(const Duration(seconds: 4))]);
}

class GymApp extends StatelessWidget {
  const GymApp({
    super.key,
    required this.app,
    required this.workout,
    required this.body,
    required this.meal,
  });

  final AppState app;
  final WorkoutState workout;
  final BodyState body;
  final MealState meal;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<WorkoutState>.value(value: workout),
        ChangeNotifierProvider<BodyState>.value(value: body),
        ChangeNotifierProvider<MealState>.value(value: meal),
      ],
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          title: 'gym',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(state.skin, font: state.profile.font),
          locale: state.locale,
          supportedLocales: const [Locale('en'), Locale('ja')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          builder: (context, child) => _PhoneFrame(child: child!),
          home: const HomeShell(),
        ),
      ),
    );
  }
}

// On wide screens (web / desktop) keep the phone layout centred in a column.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final skin = context.watch<AppState>().skin;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) return child;
        return ColoredBox(
          color: Color.lerp(skin.background, skin.heading, 0.12)!,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
