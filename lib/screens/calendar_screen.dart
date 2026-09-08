import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../l10n/strings.dart';
import '../models/enums.dart';
import '../services/streaks.dart';
import '../state/app_state.dart';
import '../state/body_state.dart';
import '../state/meal_state.dart';
import '../state/workout_state.dart';
import '../widgets/emo.dart';
import '../widgets/pastel_card.dart';
import 'home_shell.dart';
import 'workout/session_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = dayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final skin = app.skin;
    final l = app.l;
    final w = context.watch<WorkoutState>();
    final body = context.watch<BodyState>();
    final meal = context.watch<MealState>();
    final t = Theme.of(context).textTheme;

    final gymDays = w.gymDays.toSet();
    final mealDays = meal.loggedDays;
    final bodyDays = body.logs.map((x) => dayOf(x.date)).toSet();
    final streak = summarizeStreaks(gymDays, app.profile.weeklyGoalDays);
    final today = dayOf(DateTime.now());

    final leading = _month.weekday - DateTime.monday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final monthGym = gymDays.where((d) => d.year == _month.year && d.month == _month.month).length;

    final selectedSessions = w.sessionsOn(_selected).where((s) => !s.isEmpty).toList();
    final selectedBody = body.logOn(_selected);
    final selectedMeals = meal.totalsOn(_selected);

    return Scaffold(
      appBar: AppBar(title: Text(l.calendar)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(
            children: [
              Expanded(child: StatTile(label: l.streak, emo: Emo.fire, value: '${streak.dayStreak}', unit: l.daysUnit)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: l.weekStreakShort, emo: Emo.ribbon, value: '${streak.weekStreak}', unit: l.weeksUnit)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: l.monthLabel, emo: Emo.cherryBlossom, value: '$monthGym', unit: l.timesUnit)),
            ],
          ),
          const SizedBox(height: 14),
          PastelCard(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                    ),
                    Expanded(
                      child: Text(
                        l.monthYear(_month),
                        textAlign: TextAlign.center,
                        style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    for (final label in l.weekdayHeaders)
                      Expanded(
                        child: Center(
                          child: Text(label,
                              style: t.labelSmall?.copyWith(
                                  color: skin.subText, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                for (var row = 0; row < cells.length ~/ 7; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: _DayCell(
                            day: cells[row * 7 + col],
                            isToday: cells[row * 7 + col] == today,
                            isSelected: cells[row * 7 + col] == _selected,
                            gym: gymDays.contains(cells[row * 7 + col]),
                            meal: mealDays.contains(cells[row * 7 + col]),
                            body: bodyDays.contains(cells[row * 7 + col]),
                            onTap: () => setState(() => _selected = cells[row * 7 + col]!),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: skin.button, label: l.gym),
                    const SizedBox(width: 12),
                    _Legend(color: skin.accent, label: l.meals),
                    const SizedBox(width: 12),
                    _Legend(color: skin.heading, label: l.weight),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(l.dateLong(_selected), emo: Emo.pushpin),
          if (selectedSessions.isEmpty && selectedBody == null && selectedMeals.kcal == 0)
            EmptyHint(emo: Emo.bubbles, text: l.noRecords),
          for (final s in selectedSessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PastelCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SessionScreen(sessionId: s.session.id)),
                ),
                child: Row(
                  children: [
                    const EmoIcon(Emo.lifting, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _sessionLine(s, w, l),
                        style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: skin.subText),
                  ],
                ),
              ),
            ),
          if (selectedBody != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PastelCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => HomeShell.of(context)?.goTo(3),
                child: Row(
                  children: [
                    const EmoIcon(Emo.ribbon, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      l.bodyLine(selectedBody.weightKg, selectedBody.bodyFatPct),
                      style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          if (selectedMeals.kcal > 0)
            PastelCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () => HomeShell.of(context)?.goTo(4),
              child: Row(
                children: [
                  const EmoIcon(Emo.bento, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.macroLine(
                        selectedMeals.kcal.round(),
                        selectedMeals.protein.round(),
                        selectedMeals.fat.round(),
                        selectedMeals.carbs.round(),
                      ),
                      style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _sessionLine(SessionDetail s, WorkoutState w, L l) {
    final groups = <String>{};
    for (final id in s.exerciseOrder) {
      final e = w.exerciseById(id);
      if (e != null) groups.add(MuscleGroup.parse(e.muscleGroup).label(l));
    }
    final cardio = s.cardio.map((c) => CardioType.parse(c.kind).label(l)).toSet();
    return [...groups, ...cardio].join(' · ');
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.gym,
    required this.meal,
    required this.body,
    required this.onTap,
  });

  final DateTime? day;
  final bool isToday;
  final bool isSelected;
  final bool gym;
  final bool meal;
  final bool body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final d = day;
    if (d == null) return const SizedBox(height: 46);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gym ? skin.button : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: skin.heading, width: 2)
                    : isToday
                        ? Border.all(color: skin.accent, width: 2)
                        : null,
              ),
              child: gym
                  ? const EmoIcon(Emo.cherryBlossom, size: 18)
                  : Text('${d.day}',
                      style: TextStyle(
                        color: skin.text,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      )),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(visible: meal, color: skin.accent),
                _Dot(visible: body, color: skin.heading),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.visible, required this.color});
  final bool visible;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: visible ? color : Colors.transparent,
          shape: BoxShape.circle,
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: skin.subText, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
