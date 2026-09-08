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
import '../widgets/emo.dart';
import '../widgets/group_badge.dart';
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
    final name = app.profile.nickname.isEmpty
        ? ''
        : (l.isJa ? '、${app.profile.nickname}' : ', ${app.profile.nickname}');
    final slotNow = MealSlot.forNow(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.dateLong(now)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${l.greeting(now.hour)}$name',
                  style: t.headlineSmall?.copyWith(
                    color: skin.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const EmoIcon(Emo.tulip, size: 26),
            ],
          ),
          const SizedBox(height: 14),
          PastelCard(
            child: Row(
              children: [
                RingProgress(
                  value: app.profile.weeklyGoalDays == 0
                      ? 0
                      : streak.thisWeek / app.profile.weeklyGoalDays,
                  color: skin.button,
                  trackColor: skin.divider,
                  size: 92,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${streak.thisWeek}',
                          style: t.headlineSmall?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w800)),
                      Text(l.perWeek(app.profile.weeklyGoalDays),
                          style: t.labelSmall?.copyWith(color: skin.subText)),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.thisWeekGym,
                          style: t.titleMedium?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _MiniStat(label: l.weekStreakLabel, value: l.weeks(streak.weekStreak)),
                      _MiniStat(label: l.thisMonthLabel, value: l.times(streak.thisMonth)),
                      _MiniStat(label: l.allTimeLabel, value: l.times(streak.total)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (open != null)
            PastelCard(
              color: skin.buttonSoft,
              onTap: () => _openSession(context, open.session.id),
              child: Row(
                children: [
                  const EmoIcon(Emo.fire, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.workoutInProgress,
                            style: t.titleMedium?.copyWith(
                                color: skin.heading, fontWeight: FontWeight.w700)),
                        Text(
                          l.exercisesAndSets(open.exerciseOrder.length, open.sets.length),
                          style: t.bodySmall?.copyWith(color: skin.text),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: skin.heading),
                ],
              ),
            )
          else if (todaySessions.isNotEmpty)
            PastelCard(
              onTap: () => _openSession(context, todaySessions.first.session.id),
              child: Row(
                children: [
                  const EmoIcon(Emo.ribbon, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.todayWorkoutDone,
                            style: t.titleMedium?.copyWith(
                                color: skin.heading, fontWeight: FontWeight.w700)),
                        Text(
                          _sessionSummary(todaySessions.first, workout, l),
                          style: t.bodySmall?.copyWith(color: skin.subText),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: skin.subText),
                ],
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => _startSession(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.startTodayWorkout),
            ),
          const SizedBox(height: 20),
          SectionTitle(l.todayMeals, emo: Emo.bento),
          PastelCard(
            onTap: () => HomeShell.of(context)?.goTo(4),
            child: Row(
              children: [
                RingProgress(
                  value: target.kcal == 0 ? 0 : eaten.kcal / target.kcal,
                  color: skin.accent,
                  trackColor: skin.divider,
                  size: 92,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${eaten.kcal.round()}',
                          style: t.titleLarge?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w800)),
                      Text('/${target.kcal.round()}',
                          style: t.labelSmall?.copyWith(color: skin.subText)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      MacroBar(
                        label: l.p,
                        value: eaten.protein,
                        target: target.protein,
                        color: skin.button,
                        trackColor: skin.divider,
                        textColor: skin.text,
                      ),
                      const SizedBox(height: 8),
                      MacroBar(
                        label: l.f,
                        value: eaten.fat,
                        target: target.fat,
                        color: skin.accent,
                        trackColor: skin.divider,
                        textColor: skin.text,
                      ),
                      const SizedBox(height: 8),
                      MacroBar(
                        label: l.c,
                        value: eaten.carbs,
                        target: target.carbs,
                        color: skin.heading,
                        trackColor: skin.divider,
                        textColor: skin.text,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FoodPickerScreen(day: now, slot: slotNow),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(slotNow.label(l)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showBodyLogSheet(context),
                  icon: const Icon(Icons.monitor_weight_outlined),
                  label: Text(body.latestWeight == null
                      ? l.logWeight
                      : '${fmtKg(body.latestWeight!)} kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(l.todayPicks, emo: Emo.sparkles),
          for (final s in training) _TrainingCard(suggestion: s),
          const SizedBox(height: 10),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.nextMealIdeas,
                    style: t.titleSmall?.copyWith(
                        color: skin.heading, fontWeight: FontWeight.w700)),
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
                        Text(
                          '${m.food.kcal.round()} · P${m.food.protein.round()}',
                          style: t.bodySmall?.copyWith(color: skin.subText),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.add_circle_rounded, color: skin.button),
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
    );
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: skin.subText, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: skin.text, fontWeight: FontWeight.w700)),
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
              GroupBadge(suggestion.group),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  suggestion.group.label(l),
                  style: t.titleSmall?.copyWith(color: skin.heading, fontWeight: FontWeight.w700),
                ),
              ),
              if (suggestion.daysSince != null)
                Text(l.overDays(suggestion.daysSince!),
                    style: t.bodySmall?.copyWith(color: skin.subText)),
            ],
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: skin.buttonSoft,
                foregroundColor: skin.heading,
                shape: const StadiumBorder(),
              ),
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
