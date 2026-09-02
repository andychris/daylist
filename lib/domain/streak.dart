import 'date_utils.dart';
import 'models/task_lifespan.dart';

/// How far back to look when computing a streak — a bound so the query and
/// walk stay cheap; a streak longer than this is already a rare milestone.
const streakMaxLookbackDays = 400;

/// The user's current daily-completion streak as of [today]: the number of
/// consecutive days, walking backward, where every active task was
/// completed. A day with no active tasks breaks the streak (there was
/// nothing to complete, so it can't extend one).
///
/// An incomplete *today* doesn't zero out an otherwise-ongoing streak — the
/// day isn't over yet, so the walk starts from yesterday in that case and
/// today is left for the UI to show separately as "in progress."
int computeCurrentStreak({
  required DateTime today,
  required List<TaskLifespan> tasks,
  required Map<String, int> completedCountsByDate,
}) {
  bool isFullyDone(DateTime day) {
    final activeCount = tasks.where((t) => t.isDueOn(day)).length;
    if (activeCount == 0) return false;
    final completed = completedCountsByDate[formatLocalDate(day)] ?? 0;
    return completed >= activeCount;
  }

  var day = isFullyDone(today) ? today : addDays(today, -1);

  var streak = 0;
  for (var i = 0; i < streakMaxLookbackDays; i++) {
    if (!isFullyDone(day)) break;
    streak++;
    day = addDays(day, -1);
  }
  return streak;
}
