import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'body_screen.dart';
import 'calendar_screen.dart';
import 'meals/meals_screen.dart';
import 'today_screen.dart';
import 'workout/workout_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();

  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;

  void goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final skin = context.skin;
    final size = MediaQuery.sizeOf(context);
    // Landscape phones have little height to spare, so move the tabs to the side.
    final sideNav = size.height < 500 && size.width > size.height;
    final pages = const [
      TodayScreen(),
      WorkoutListScreen(),
      CalendarScreen(),
      BodyScreen(),
      MealsScreen(),
    ];
    final items = [
      (Icons.home_outlined, Icons.home_rounded, l.navHome),
      (Icons.fitness_center_outlined, Icons.fitness_center_rounded, l.navWorkout),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, l.navCalendar),
      (Icons.monitor_weight_outlined, Icons.monitor_weight_rounded, l.navBody),
      (Icons.restaurant_outlined, Icons.restaurant_rounded, l.navMeals),
    ];
    final body = IndexedStack(index: _index, children: pages);

    if (sideNav) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: goTo,
              backgroundColor: skin.card,
              indicatorColor: skin.buttonSoft,
              labelType: NavigationRailLabelType.all,
              minWidth: 64,
              selectedIconTheme: IconThemeData(color: skin.heading),
              unselectedIconTheme: IconThemeData(color: skin.subText),
              selectedLabelTextStyle: TextStyle(
                color: skin.heading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: skin.subText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              destinations: [
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: skin.divider),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final (icon, selected, label) in items)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
