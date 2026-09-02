import 'date_utils.dart';
import 'models/day_rings.dart';
import 'models/task_lifespan.dart';

const _consistencyWindowDays = 7;

/// Computes per-day ring values for every day in the month containing
/// [monthAnchor], given every task whose lifespan could overlap that month
/// (plus the [_consistencyWindowDays] - 1 days before it) and a map of
/// completed-task counts keyed by 'YYYY-MM-DD'.
///
/// Days after [today] always come back as "nothing happened yet" — a task
/// being active doesn't mean anything for a day that hasn't occurred.
List<DayRings> computeMonthRings({
  required DateTime monthAnchor,
  required List<TaskLifespan> tasks,
  required Map<String, int> completedCountsByDate,
  required DateTime today,
}) {
  final monthStart = DateTime(monthAnchor.year, monthAnchor.month, 1);
  final monthEnd = DateTime(monthAnchor.year, monthAnchor.month + 1, 0);
  final rangeStart = addDays(monthStart, -(_consistencyWindowDays - 1));

  // Progress fraction (or null if no active tasks, or the day is in the
  // future) for every day in the lookback range, so the rolling average can
  // reach into the prior month.
  final progressByDay = <DateTime, double?>{};
  for (
    var day = rangeStart;
    !day.isAfter(monthEnd);
    day = addDays(day, 1)
  ) {
    if (day.isAfter(today)) {
      progressByDay[day] = null;
      continue;
    }
    final activeCount = tasks.where((t) => t.isDueOn(day)).length;
    if (activeCount == 0) {
      progressByDay[day] = null;
      continue;
    }
    final completed = completedCountsByDate[formatLocalDate(day)] ?? 0;
    progressByDay[day] = completed / activeCount;
  }

  final results = <DayRings>[];
  for (
    var day = monthStart;
    !day.isAfter(monthEnd);
    day = addDays(day, 1)
  ) {
    if (day.isAfter(today)) {
      results.add(
        DayRings(
          date: day,
          hasGoal: false,
          totalActive: 0,
          completed: 0,
          progressFraction: 0.0,
          consistencyFraction: null,
        ),
      );
      continue;
    }

    final activeCount = tasks.where((t) => t.isDueOn(day)).length;
    final completed = completedCountsByDate[formatLocalDate(day)] ?? 0;
    final progressFraction = activeCount == 0 ? 0.0 : completed / activeCount;

    final windowFractions = <double>[];
    for (var i = 0; i < _consistencyWindowDays; i++) {
      final windowDay = addDays(day, -i);
      if (windowDay.isBefore(rangeStart)) break;
      final fraction = progressByDay[windowDay];
      if (fraction != null) windowFractions.add(fraction);
    }
    final consistencyFraction = windowFractions.isEmpty
        ? null
        : windowFractions.reduce((a, b) => a + b) / windowFractions.length;

    results.add(
      DayRings(
        date: day,
        hasGoal: activeCount > 0,
        totalActive: activeCount,
        completed: completed,
        progressFraction: progressFraction,
        consistencyFraction: consistencyFraction,
      ),
    );
  }

  return results;
}
