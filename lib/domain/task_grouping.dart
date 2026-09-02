import 'due_logic.dart';
import 'models/checklist_item.dart';

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

    if (task.dueDate == null) {
      inbox.add(task);
      continue;
    }

    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    if (due.isBefore(today)) {
      overdue.add(task);
    } else if (due.isAtSameMomentAs(today)) {
      dueToday.add(task);
    } else {
      upcoming.putIfAbsent(due, () => []).add(task);
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
