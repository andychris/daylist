import 'due_logic.dart';
import 'models/checklist_item.dart';

enum DueBucket { overdue, dueToday, upcoming, inbox }

/// Classifies a single task's due-ness as of [today] — the same rule
/// [groupTasksByDueness] uses per-task, exposed separately so the filter
/// engine (`p1 & (today | overdue)`) can reuse the exact same logic rather
/// than a parallel definition that could drift out of sync.
DueBucket classifyDueBucket(ChecklistItem task, DateTime today) {
  if (task.recurrenceRule != null) {
    // A recurring task is never "Inbox" or "Overdue" — it's either due
    // today, or due again on some future day its rule matches, which
    // `upcoming` is the closest fit for (nothing here claims a *specific*
    // future date the way a one-off task's upcoming bucket does).
    return matchesRecurrence(task.recurrenceRule!, today, task.createdAt)
        ? DueBucket.dueToday
        : DueBucket.upcoming;
  }

  if (task.dueDate == null) return DueBucket.inbox;

  final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
  if (due.isBefore(today)) return DueBucket.overdue;
  if (due.isAtSameMomentAs(today)) return DueBucket.dueToday;
  return DueBucket.upcoming;
}

class GroupedTasks {
  const GroupedTasks({
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
    required this.inbox,
  });

  /// Non-recurring tasks whose due date is before today and still
  /// incomplete — rolls forward day after day until done or rescheduled.
  final List<ChecklistItem> overdue;

  /// Recurring tasks whose rule matches today, plus non-recurring tasks
  /// due exactly today.
  final List<ChecklistItem> dueToday;

  /// Non-recurring tasks due on a future day, keyed by that local-midnight
  /// date (ascending).
  final Map<DateTime, List<ChecklistItem>> upcoming;

  /// Tasks with no due date and no recurrence — pure Inbox items.
  final List<ChecklistItem> inbox;
}

/// Buckets [tasks] (every currently-active task) into Overdue/Today/
/// Upcoming/Inbox as of [today], the same due-ness rules [isTaskDueOn]
/// uses elsewhere (streak, calendar rings, history) — a recurring task
/// whose rule doesn't match today simply doesn't appear in any bucket
/// today, matching Todoist (a "Tuesday only" task doesn't show on Monday).
GroupedTasks groupTasksByDueness(List<ChecklistItem> tasks, DateTime today) {
  final overdue = <ChecklistItem>[];
  final dueToday = <ChecklistItem>[];
  final upcoming = <DateTime, List<ChecklistItem>>{};
  final inbox = <ChecklistItem>[];

  for (final task in tasks) {
    if (task.recurrenceRule != null) {
      if (matchesRecurrence(task.recurrenceRule!, today, task.createdAt)) {
        dueToday.add(task);
      }
      continue;
    }

    switch (classifyDueBucket(task, today)) {
      case DueBucket.overdue:
        overdue.add(task);
      case DueBucket.dueToday:
        dueToday.add(task);
      case DueBucket.upcoming:
        final due = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        upcoming.putIfAbsent(due, () => []).add(task);
      case DueBucket.inbox:
        inbox.add(task);
    }
  }

  int bySortOrder(ChecklistItem a, ChecklistItem b) =>
      a.sortOrder.compareTo(b.sortOrder);
  overdue.sort(bySortOrder);
  dueToday.sort(bySortOrder);
  inbox.sort(bySortOrder);
  for (final list in upcoming.values) {
    list.sort(bySortOrder);
  }

  return GroupedTasks(
    overdue: overdue,
    dueToday: dueToday,
    upcoming: Map.fromEntries(
      upcoming.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    inbox: inbox,
  );
}
