import 'package:flutter_test/flutter_test.dart';
import 'package:gym/models/enums.dart';
import 'package:gym/models/profile.dart';
import 'package:gym/services/nutrition.dart';
import 'package:gym/services/streaks.dart';

void main() {
  group('streaks', () {
    test('counts this week and consecutive weeks', () {
      final now = DateTime(2026, 9, 9);
      final days = [
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 8),
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 3),
        DateTime(2026, 8, 25),
        DateTime(2026, 8, 27),
        DateTime(2026, 8, 12),
      ];
      final s = summarizeStreaks(days, 2, now);
      expect(s.thisWeek, 2);
      expect(s.weekStreak, 3);
      expect(s.dayStreak, 2);
      expect(s.thisMonth, 4);
      expect(s.total, 7);
    });

    test('week streak excludes an unfinished current week', () {
      final now = DateTime(2026, 9, 9);
      final days = [DateTime(2026, 9, 1), DateTime(2026, 9, 3), DateTime(2026, 9, 7)];
      final s = summarizeStreaks(days, 2, now);
      expect(s.thisWeek, 1);
      expect(s.weekStreak, 1);
    });
  });

  group('nutrition', () {
    test('female maintenance targets follow Mifflin-St Jeor', () {
      final p = UserProfile(
        sex: Sex.female,
        birthYear: DateTime.now().year - 25,
        heightCm: 160,
        activity: ActivityLevel.light,
        goal: Goal.maintain,
      );
      final bmr = basalMetabolicRate(p, 55);
      expect(bmr, closeTo(1264, 0.5));
      final t = computeTargets(p, 55);
      expect(t.kcal, closeTo(1264 * 1.375, 1));
      expect(t.protein, closeTo(88, 0.1));
      expect(t.fat, closeTo(t.kcal * 0.25 / 9, 0.01));
    });

    test('overrides win over the formula', () {
      const p = UserProfile(kcalOverride: 1800, proteinOverride: 120);
      final t = computeTargets(p, 60);
      expect(t.kcal, 1800);
      expect(t.protein, 120);
    });
  });
}
