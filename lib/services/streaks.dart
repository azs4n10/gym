import '../data/database.dart';

DateTime weekStart(DateTime d) {
  final day = dayOf(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

class StreakSummary {
  const StreakSummary({
    required this.thisWeek,
    required this.weekStreak,
    required this.thisMonth,
    required this.total,
    required this.dayStreak,
  });

  final int thisWeek;
  final int weekStreak;
  final int thisMonth;
  final int total;
  final int dayStreak;
}

StreakSummary summarizeStreaks(Iterable<DateTime> gymDays, int weeklyGoal,
    [DateTime? now]) {
  final today = dayOf(now ?? DateTime.now());
  final days = gymDays.map(dayOf).toSet();
  final thisWeekStart = weekStart(today);

  int countWeek(DateTime start) => days
      .where((d) => !d.isBefore(start) && d.isBefore(start.add(const Duration(days: 7))))
      .length;

  final thisWeek = countWeek(thisWeekStart);
  var weekStreak = 0;
  var cursor = thisWeek >= weeklyGoal
      ? thisWeekStart
      : thisWeekStart.subtract(const Duration(days: 7));
  while (countWeek(cursor) >= weeklyGoal) {
    weekStreak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }

  var dayStreak = 0;
  var d = days.contains(today) ? today : today.subtract(const Duration(days: 1));
  while (days.contains(d)) {
    dayStreak++;
    d = d.subtract(const Duration(days: 1));
  }

  final thisMonth =
      days.where((x) => x.year == today.year && x.month == today.month).length;

  return StreakSummary(
    thisWeek: thisWeek,
    weekStreak: weekStreak,
    thisMonth: thisMonth,
    total: days.length,
    dayStreak: dayStreak,
  );
}
