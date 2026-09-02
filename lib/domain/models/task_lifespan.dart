import '../due_logic.dart';

class TaskLifespan {
  const TaskLifespan({
    required this.id,
    required this.createdAt,
    required this.archivedAt,
    required this.recurrenceRule,
    required this.dueDate,
  });

  final int id;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final String? recurrenceRule;
  final DateTime? dueDate;

  /// See [isTaskDueOn].
  bool isDueOn(DateTime day) => isTaskDueOn(
    createdAt: createdAt,
    archivedAt: archivedAt,
    recurrenceRule: recurrenceRule,
    dueDate: dueDate,
    day: day,
  );
}
