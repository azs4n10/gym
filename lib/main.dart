import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/connection.dart';
import 'data/database.dart';
import 'screens/home_shell.dart';
import 'widgets/grid_background.dart';
import 'state/app_state.dart';
import 'state/body_state.dart';
import 'state/meal_state.dart';
import 'state/workout_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(await _start().timeout(const Duration(seconds: 40)));
  } catch (e, s) {
    // A failure before the first frame would otherwise leave the boot screen
    // and then a blank page; show what went wrong instead.
    runApp(StartupError(error: e, stack: s));
  }
}

Future<Widget> _start() async {
  await Future.wait([initializeDateFormatting('en'), initializeDateFormatting('ja')]);

  final db = AppDatabase(openConnection());
  final app = await AppState.create();
  final workout = WorkoutState(db);
  final body = BodyState(db);
  final meal = MealState(db);
  await Future.wait([workout.load(), body.load(), meal.load()]);

  return GymApp(app: app, workout: workout, body: body, meal: meal);
}

class StartupError extends StatelessWidget {
  const StartupError({super.key, required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFDF0F5),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'The app could not start',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4A3550)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Close every tab or window of the app, then open it again. If this keeps happening, send the text below.',
                style: TextStyle(color: Color(0xFF4A3550)),
              ),
              const SizedBox(height: 16),
              SelectableText(
                '$error\n\n$stack',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF4A3550)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        final page = GridBackground(skin: skin, child: child);
        if (c.maxWidth < 900) return page;
        return ColoredBox(
          color: Color.lerp(skin.background, skin.heading, 0.12)!,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: page,
            ),
          ),
        );
      },
    );
  }
}
