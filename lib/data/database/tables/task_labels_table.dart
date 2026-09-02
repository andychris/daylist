import 'package:drift/drift.dart';

import 'labels_table.dart';
import 'tasks_table.dart';

@DataClassName('TaskLabelRow')
class TaskLabels extends Table {
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get labelId => integer().references(Labels, #id)();

  @override
  Set<Column> get primaryKey => {taskId, labelId};
}
