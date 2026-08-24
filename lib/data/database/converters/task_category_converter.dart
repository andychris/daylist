import 'package:drift/drift.dart';

import '../../../domain/models/task_category.dart';

class TaskCategoryConverter extends TypeConverter<TaskCategory, String> {
  const TaskCategoryConverter();

  @override
  TaskCategory fromSql(String fromDb) =>
      TaskCategory.values.asNameMap()[fromDb] ?? TaskCategory.other;

  @override
  String toSql(TaskCategory value) => value.name;
}
