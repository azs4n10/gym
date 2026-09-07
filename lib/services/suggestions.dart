import '../data/database.dart';
import '../models/enums.dart';
import 'nutrition.dart';

class ExercisePlan {
  const ExercisePlan({
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.sets,
  });

  final Exercise exercise;
  final double weightKg;
  final int reps;
  final int sets;
}

class TrainingSuggestion {
  const TrainingSuggestion({
    required this.group,
    required this.daysSince,
    required this.plans,
  });

  final MuscleGroup group;
  final int? daysSince;
  final List<ExercisePlan> plans;
}

class SetRecord {
  const SetRecord({required this.date, required this.set});
  final DateTime date;
  final WorkoutSet set;
}

const _groupPriority = [
  MuscleGroup.legs,
  MuscleGroup.back,
  MuscleGroup.chest,
  MuscleGroup.glutes,
  MuscleGroup.shoulders,
  MuscleGroup.arms,
  MuscleGroup.core,
];

const _targetReps = 10;

List<TrainingSuggestion> suggestTraining({
  required List<Exercise> exercises,
  required List<SetRecord> history,
  DateTime? now,
  int groupCount = 2,
}) {
  final today = dayOf(now ?? DateTime.now());
  final byId = {for (final e in exercises) e.id: e};

  final lastByGroup = <MuscleGroup, DateTime>{};
  final countByExercise = <int, int>{};
  final lastSessionSets = <int, List<WorkoutSet>>{};
  final lastSessionDate = <int, DateTime>{};

  for (final r in history) {
    final ex = byId[r.set.exerciseId];
    if (ex == null) continue;
    final g = MuscleGroup.parse(ex.muscleGroup);
    final d = dayOf(r.date);
    if (lastByGroup[g] == null || d.isAfter(lastByGroup[g]!)) {
      lastByGroup[g] = d;
    }
    countByExercise[ex.id] = (countByExercise[ex.id] ?? 0) + 1;
    final prev = lastSessionDate[ex.id];
    if (prev == null || d.isAfter(prev)) {
      lastSessionDate[ex.id] = d;
      lastSessionSets[ex.id] = [r.set];
    } else if (d == prev) {
      lastSessionSets[ex.id]!.add(r.set);
    }
  }

  int? daysSince(MuscleGroup g) {
    final last = lastByGroup[g];
    return last == null ? null : today.difference(last).inDays;
  }

  final ranked = [..._groupPriority]..sort((a, b) {
      final da = daysSince(a) ?? 9999;
      final db = daysSince(b) ?? 9999;
      if (da != db) return db.compareTo(da);
      return _groupPriority.indexOf(a).compareTo(_groupPriority.indexOf(b));
    });

  final result = <TrainingSuggestion>[];
  for (final g in ranked.take(groupCount)) {
    final candidates = exercises
        .where((e) => !e.isArchived && MuscleGroup.parse(e.muscleGroup) == g)
        .toList()
      ..sort((a, b) {
        final ca = countByExercise[a.id] ?? 0;
        final cb = countByExercise[b.id] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
        return a.id.compareTo(b.id);
      });
    final plans = candidates.take(3).map((e) => _planFor(e, g, lastSessionSets[e.id])).toList();
    result.add(TrainingSuggestion(group: g, daysSince: daysSince(g), plans: plans));
  }
  return result;
}

ExercisePlan _planFor(Exercise e, MuscleGroup g, List<WorkoutSet>? last) {
  if (last == null || last.isEmpty) {
    return ExercisePlan(exercise: e, weightKg: 0, reps: _targetReps, sets: 3);
  }
  final maxWeight = last.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
  final topSets = last.where((s) => s.weightKg == maxWeight).toList();
  final allHit = topSets.every((s) => s.reps >= _targetReps);
  final sets = last.length.clamp(2, 5);
  final lowerBody = g == MuscleGroup.legs || g == MuscleGroup.glutes;

  if (maxWeight == 0) {
    final maxReps = topSets.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    return ExercisePlan(exercise: e, weightKg: 0, reps: maxReps + 2, sets: sets);
  }
  if (allHit) {
    final inc = lowerBody ? 5.0 : 2.5;
    return ExercisePlan(exercise: e, weightKg: maxWeight + inc, reps: _targetReps, sets: sets);
  }
  final minReps = topSets.map((s) => s.reps).reduce((a, b) => a < b ? a : b);
  return ExercisePlan(
    exercise: e,
    weightKg: maxWeight,
    reps: (minReps + 1).clamp(1, _targetReps),
    sets: sets,
  );
}

class MealSuggestion {
  const MealSuggestion({required this.food});
  final Food food;
}

List<MealSuggestion> suggestMeals({
  required List<Food> foods,
  required Macros target,
  required Macros eaten,
  required Goal goal,
  int count = 5,
}) {
  final remain = target - eaten;
  if (remain.kcal <= 50) {
    final light = foods.where((f) => f.kcal <= 60 && !f.isCustom).take(count);
    return [for (final f in light) MealSuggestion(food: f)];
  }

  double need(double r, double t) => t <= 0 ? 0 : (r / t).clamp(0, 1);
  final pNeed = need(remain.protein, target.protein);
  final fNeed = need(remain.fat, target.fat);
  final cNeed = need(remain.carbs, target.carbs);

  final scored = <(Food, double)>[];
  for (final f in foods) {
    if (f.kcal < 10) continue;
    final pShare = f.protein * 4 / f.kcal;
    final fShare = f.fat * 9 / f.kcal;
    final cShare = f.carbs * 4 / f.kcal;
    var score = pNeed * pShare * 1.6 + cNeed * cShare * 0.9 + fNeed * fShare * 0.6;
    // Tiny servings barely move the needle, so weight by how much they contribute.
    score *= (f.kcal / 120).clamp(0.3, 1.0);
    if (f.kcal > remain.kcal) score *= 0.3;
    if (FoodTag.parse(f.tag) == FoodTag.sweet) {
      score *= goal == Goal.cut ? 0.2 : 0.5;
    }
    if (f.protein >= 15) score += 0.15 * pNeed;
    scored.add((f, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (f, _) in scored.take(count)) MealSuggestion(food: f)];
}
