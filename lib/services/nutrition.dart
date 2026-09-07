import '../models/enums.dart';
import '../models/profile.dart';

class Macros {
  const Macros({
    this.kcal = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
  });

  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  Macros operator +(Macros o) => Macros(
        kcal: kcal + o.kcal,
        protein: protein + o.protein,
        fat: fat + o.fat,
        carbs: carbs + o.carbs,
      );

  Macros operator -(Macros o) => Macros(
        kcal: kcal - o.kcal,
        protein: protein - o.protein,
        fat: fat - o.fat,
        carbs: carbs - o.carbs,
      );

  Macros scale(double k) => Macros(
        kcal: kcal * k,
        protein: protein * k,
        fat: fat * k,
        carbs: carbs * k,
      );
}

const double defaultWeightKg = 55;

double basalMetabolicRate(UserProfile p, double weightKg) {
  // Mifflin-St Jeor
  final base = 10 * weightKg + 6.25 * p.heightCm - 5 * p.age;
  return p.sex == Sex.male ? base + 5 : base - 161;
}

Macros computeTargets(UserProfile p, double? weightKg) {
  final w = weightKg ?? defaultWeightKg;
  final tdee = basalMetabolicRate(p, w) * p.activity.factor;
  final kcal = (p.kcalOverride ?? (tdee + p.goal.kcalOffset)).clamp(1000, 5000).toDouble();
  final proteinPerKg = switch (p.goal) {
    Goal.cut => 2.0,
    Goal.maintain => 1.6,
    Goal.bulk => 1.8,
  };
  final protein = p.proteinOverride ?? w * proteinPerKg;
  final fat = p.fatOverride ?? kcal * 0.25 / 9;
  final carbs = p.carbsOverride ??
      ((kcal - protein * 4 - fat * 9) / 4).clamp(50, 1000).toDouble();
  return Macros(kcal: kcal, protein: protein, fat: fat, carbs: carbs);
}
