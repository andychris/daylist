import 'task_category.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    required this.isDoneToday,
    required this.sortOrder,
    required this.category,
    required this.reminderMinuteOfDay,
  });

  final int id;
  final String title;
  final bool isDoneToday;
  final double sortOrder;
  final TaskCategory category;

  /// Minutes since midnight for a daily-repeating reminder, or null if this
  /// task has no reminder.
  final int? reminderMinuteOfDay;

  ChecklistItem copyWith({bool? isDoneToday}) => ChecklistItem(
    id: id,
    title: title,
    isDoneToday: isDoneToday ?? this.isDoneToday,
    sortOrder: sortOrder,
    category: category,
    reminderMinuteOfDay: reminderMinuteOfDay,
  );
}
