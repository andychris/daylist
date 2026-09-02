import 'task_category.dart';
import 'task_priority.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    required this.isDoneToday,
    required this.sortOrder,
    required this.category,
    required this.reminderMinuteOfDay,
    required this.priority,
    required this.projectId,
    required this.dueDate,
    required this.recurrenceRule,
    required this.createdAt,
    required this.sectionId,
  });

  final int id;
  final String title;
  final bool isDoneToday;
  final double sortOrder;
  final TaskCategory category;

  /// Minutes since midnight for a daily-repeating reminder, or null if this
  /// task has no reminder.
  final int? reminderMinuteOfDay;

  final TaskPriority priority;

  /// Null means the task is in Inbox (no project).
  final int? projectId;
  final DateTime? dueDate;
  final String? recurrenceRule;
  final DateTime createdAt;

  /// Null means the task isn't placed in a Kanban section (e.g. Inbox, or
  /// a project with no board view).
  final int? sectionId;

  ChecklistItem copyWith({bool? isDoneToday}) => ChecklistItem(
    id: id,
    title: title,
    isDoneToday: isDoneToday ?? this.isDoneToday,
    sortOrder: sortOrder,
    category: category,
    reminderMinuteOfDay: reminderMinuteOfDay,
    priority: priority,
    projectId: projectId,
    dueDate: dueDate,
    recurrenceRule: recurrenceRule,
    createdAt: createdAt,
    sectionId: sectionId,
  );
}
