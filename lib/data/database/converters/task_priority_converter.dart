import 'package:drift/drift.dart';

import '../../../domain/models/task_priority.dart';

class TaskPriorityConverter extends TypeConverter<TaskPriority, String> {
  const TaskPriorityConverter();

  @override
  TaskPriority fromSql(String fromDb) =>
      TaskPriority.values.asNameMap()[fromDb] ?? TaskPriority.p4;

  @override
  String toSql(TaskPriority value) => value.name;
}
