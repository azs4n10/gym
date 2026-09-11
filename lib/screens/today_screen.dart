import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed/exercises_seed.dart';
import '../data/seed/foods_seed.dart';
import '../l10n/strings.dart';
import '../models/enums.dart';
import '../services/nutrition.dart';
import '../services/streaks.dart';
import '../services/suggestions.dart';
import '../state/app_state.dart';
import '../state/body_state.dart';
import '../state/meal_state.dart';
import '../state/workout_state.dart';
import '../widgets/app_icon.dart';
import '../widgets/cover.dart';
import '../widgets/hero_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/pastel_card.dart';
import '../widgets/ring_progress.dart';
import 'body_screen.dart';
import 'home_shell.dart';
import 'meals/food_picker_screen.dart';
import 'settings_screen.dart';
import 'workout/session_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final skin = app.skin;
    final l = app.l;
    final workout = context.watch<WorkoutState>();
    final body = context.watch<BodyState>();
    final meal = context.watch<MealState>();
    final now = DateTime.now();
    final t = Theme.of(context).textTheme;

    final streak = summarizeStreaks(workout.gymDays, app.profile.weeklyGoalDays);
    final target = computeTargets(app.profile, body.latestWeight);
    final eaten = meal.totalsOn(now);
    final training = suggestTraining(
      exercises: workout.activeExercises,
      history: workout.history,
      groupCount: 1,
    );
    final mealIdeas = suggestMeals(
      foods: meal.foods,
      target: target,
      eaten: eaten,
      goal: app.profile.goal,
      count: 3,
    );
    final open = workout.openSession;
    final todaySessions = workout.sessionsOn(now).where((s) => !s.isEmpty).toList();
    final todayMinutes = _minutesOn(workout, now);
    final slotNow = MealSlot.forNow(now);
    final goal = app.profile.weeklyGoalDays;
    final progress = goal == 0 ? 0.0 : streak.thisWeek / goal;
    final name = app.profile.nickname;
    final onHero = skin.buttonText;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: skin.buttonSoft, shape: BoxShape.circle),
                  child: name.isEmpty
                      ? const AppIcon(Ic.profile, size: 26)
                      : Text(name.characters.first.toUpperCase(),
                          style: t.titleLarge?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.hi(name),
                          style: t.titleLarge?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w800)),
                      Text(l.dateLong(now), style: t.bodySmall?.copyWith(color: skin.subText)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: skin.heading),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            HeroCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.thisWeekGym,
                            style: t.labelLarge?.copyWith(
                                color: onHero.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${streak.thisWeek}',
                                style: t.displayMedium?.copyWith(
                                    color: onHero, fontWeight: FontWeight.w800, height: 1)),
                            Text(' / $goal',
                                style: t.titleMedium?.copyWith(color: onHero.withValues(alpha: 0.85))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _HeroPill(ic: Ic.workout, text: l.minutes(todayMinutes)),
                            _HeroPill(ic: Ic.streak, text: l.weeks(streak.weekStreak)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  RingProgress(
                    value: progress,
                    color: onHero,
                    trackColor: onHero.withValues(alpha: 0.25),
                    size: 96,
                    stroke: 10,
                    child: Text('${(progress * 100).round()}%',
                        style: t.titleMedium?.copyWith(color: onHero, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: l.calories,
                    ic: Ic.meals,
                    value: '${eaten.kcal.round()}',
                    unit: '/ ${target.kcal.round()}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: l.protein,
                    ic: Ic.lunch,
                    value: '${eaten.protein.round()}',
                    unit: '/ ${target.protein.round()} g',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: l.weight,
                    ic: Ic.body,
                    value: body.latestWeight == null ? '--' : fmtKg(body.latestWeight!),
                    unit: 'kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PastelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.weeklyActivity,
                      style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _WeekBars(minutes: _weekMinutes(workout, now), today: now),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l.quickActions,
                style: t.titleLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    ic: Ic.workout,
                    label: open == null ? l.startTodayWorkout : l.continueWorkout,
                    color: skin.buttonSoft,
                    onTap: () => _startSession(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    ic: Ic.meals,
                    label: l.logFood,
                    color: skin.accentSoft,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FoodPickerScreen(day: now, slot: slotNow)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    ic: Ic.body,
                    label: l.body,
                    color: Color.lerp(skin.heading, skin.card, 0.82)!,
                    onTap: () => showBodyLogSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    ic: Ic.month,
                    label: l.calendar,
                    color: Color.lerp(skin.button, skin.card, 0.45)!,
                    onTap: () => HomeShell.of(context)?.goTo(2),
                  ),
                ),
              ],
            ),
            if (open != null || todaySessions.isNotEmpty) ...[
              const SizedBox(height: 20),
              PastelCard(
                color: open != null ? skin.buttonSoft : null,
                onTap: () => _openSession(context, (open ?? todaySessions.first).session.id),
                child: Row(
                  children: [
                    IconTile(open != null ? Ic.fire : Ic.done, color: skin.card),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(open != null ? l.workoutInProgress : l.todayWorkoutDone,
                              style: t.titleMedium?.copyWith(
                                  color: skin.heading, fontWeight: FontWeight.w700)),
                          Text(
                            open != null
                                ? l.exercisesAndSets(open.exerciseOrder.length, open.sets.length)
                                : _sessionSummary(todaySessions.first, workout, l),
                            style: t.bodySmall?.copyWith(color: skin.subText),
                          ),
                        ],
                      ),
                    ),
                    const GoButton(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(l.todayPicks,
                      style: t.titleLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => HomeShell.of(context)?.goTo(1),
                  child: Text(l.seeAll),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final s in training) _TrainingCard(suggestion: s),
            const SizedBox(height: 10),
            PastelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nextMealIdeas,
                      style: t.titleSmall?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  if (mealIdeas.isEmpty)
                    Text(l.foodListEmpty, style: TextStyle(color: skin.subText))
                  else
                    for (final m in mealIdeas)
                      Row(
                        children: [
                          Expanded(
                            child: Text(foodName(m.food, l),
                                style: t.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600, color: skin.text)),
                          ),
                          Text('${m.food.kcal.round()} · P${m.food.protein.round()}',
                              style: t.bodySmall?.copyWith(color: skin.subText)),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.add_circle_rounded, color: skin.heading),
                            onPressed: () async {
                              await meal.addFood(now, slotNow, m.food, 1);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.added)),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _minutesOn(WorkoutState w, DateTime day) {
    var total = 0;
    for (final s in w.sessionsOn(day)) {
      if (s.isEmpty) continue;
      total += _sessionMinutes(s);
    }
    return total;
  }

  List<int> _weekMinutes(WorkoutState w, DateTime now) {
    final start = weekStart(now);
    return [for (var i = 0; i < 7; i++) _minutesOn(w, start.add(Duration(days: i)))];
  }

  static int _sessionMinutes(SessionDetail s) {
    final end = s.session.endedAt ?? DateTime.now();
    return end.difference(s.session.startedAt).inMinutes.clamp(0, 300);
  }

  String _sessionSummary(SessionDetail s, WorkoutState w, L l) {
    final names = s.exerciseOrder
        .map((id) => w.exerciseById(id))
        .whereType()
        .map((e) => exerciseName(e, l))
        .take(3)
        .join(' · ');
    final cardio = s.cardio.map((c) => CardioType.parse(c.kind).label(l)).join(' · ');
    return [if (names.isNotEmpty) names, if (cardio.isNotEmpty) cardio].join(' / ');
  }

  Future<void> _startSession(BuildContext context) async {
    final id = await context.read<WorkoutState>().startSession();
    if (context.mounted) _openSession(context, id);
  }

  void _openSession(BuildContext context, int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionScreen(sessionId: id)),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.ic, required this.text});
  final Ic ic;
  final String text;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(ic, size: 14, color: skin.buttonText),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(color: skin.buttonText, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.minutes, required this.today});
  final List<int> minutes;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final max = minutes.fold<int>(0, (m, v) => v > m ? v : m);
    final todayIndex = today.weekday - DateTime.monday;
    return SizedBox(
      height: 104,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (minutes[i] > 0)
                    Text('${minutes[i]}',
                        style: TextStyle(color: skin.subText, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: 14,
                    height: max == 0 ? 6 : 6 + 60 * minutes[i] / max,
                    decoration: BoxDecoration(
                      color: i == todayIndex
                          ? skin.heading
                          : minutes[i] > 0
                              ? skin.button
                              : skin.divider,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == todayIndex ? skin.buttonSoft : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(l.weekdayHeaders[i],
                        style: TextStyle(
                          color: i == todayIndex ? skin.heading : skin.subText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.ic,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Ic ic;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return PastelCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(ic, size: 40, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                style: TextStyle(color: skin.text, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.suggestion});
  final TrainingSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoverThumb(ic: suggestion.group.ic, tint: suggestion.group.color, size: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestion.group.label(l),
                  style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800),
                ),
              ),
              if (suggestion.daysSince != null)
                Text(l.overDays(suggestion.daysSince!),
                    style: t.bodySmall?.copyWith(color: skin.subText)),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in suggestion.plans)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(exerciseName(p.exercise, l),
                        style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: skin.text)),
                  ),
                  Text(
                    l.planLine(
                      p.weightKg == 0 ? l.bodyweight : '${fmtKg(p.weightKg)}kg',
                      p.reps,
                      p.sets,
                    ),
                    style: t.bodySmall?.copyWith(
                        color: skin.heading, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final w = context.read<WorkoutState>();
                final id = await w.startSession();
                for (final p in suggestion.plans) {
                  if (w.sessionById(id)!.setsFor(p.exercise.id).isEmpty) {
                    await w.addSet(id, p.exercise.id, weightKg: p.weightKg, reps: p.reps);
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SessionScreen(sessionId: id)),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(l.start),
            ),
          ),
        ],
      ),
    );
  }
}
