import 'date_utils.dart';

const Map<String, int> _weekdayCodes = {
  'MON': DateTime.monday,
  'TUE': DateTime.tuesday,
  'WED': DateTime.wednesday,
  'THU': DateTime.thursday,
  'FRI': DateTime.friday,
  'SAT': DateTime.saturday,
  'SUN': DateTime.sunday,
};

/// Whether a task recurring per [rule] falls on [day]. [anchor] is the
/// recurrence's start date (a task's creation day), used by cadence rules
/// like `every:N` to count elapsed days. Supported rule strings: `daily`,
/// `weekdays`, `weekly:MON`..`weekly:SUN`, `monthly:1`..`monthly:31`,
/// `every:N` (every N days, starting on [anchor]). An unrecognized rule
/// never matches.
bool matchesRecurrence(String rule, DateTime day, DateTime anchor) {
  if (rule == 'daily') return true;
  if (rule == 'weekdays') return day.weekday <= DateTime.friday;

  if (rule.startsWith('weekly:')) {
    final weekday = _weekdayCodes[rule.substring('weekly:'.length)];
    return weekday != null && day.weekday == weekday;
  }

  if (rule.startsWith('monthly:')) {
    final dayOfMonth = int.tryParse(rule.substring('monthly:'.length));
    return dayOfMonth != null && day.day == dayOfMonth;
  }

  if (rule.startsWith('every:')) {
    final n = int.tryParse(rule.substring('every:'.length));
    if (n == null || n <= 0) return false;
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final targetDay = DateTime(day.year, day.month, day.day);
    if (targetDay.isBefore(anchorDay)) return false;
    return targetDay.difference(anchorDay).inDays % n == 0;
  }

  return false;
}

/// Whether a task is "due" on [day]: active (see [isTaskActiveOn]) and
/// either matching its [recurrenceRule], or — for a one-off task
/// ([recurrenceRule] null) — on or after its [dueDate]. A one-off task
/// with no [dueDate] at all (a pure Inbox item) is never due; it only
/// shows up in Inbox/project views. An overdue one-off task stays due on
/// every subsequent day until it's completed (and archived) or
/// rescheduled, matching Todoist's overdue behavior.
bool isTaskDueOn({
  required DateTime createdAt,
  required DateTime? archivedAt,
  required String? recurrenceRule,
  required DateTime? dueDate,
  required DateTime day,
}) {
  if (!isTaskActiveOn(createdAt, archivedAt, day)) return false;

  if (recurrenceRule != null) {
    return matchesRecurrence(recurrenceRule, day, createdAt);
  }

  if (dueDate == null) return false;
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final targetDay = DateTime(day.year, day.month, day.day);
  return !targetDay.isBefore(dueDay);
}
