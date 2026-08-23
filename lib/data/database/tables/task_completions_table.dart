import 'package:drift/drift.dart';

import 'tasks_table.dart';

@DataClassName('TaskCompletionRow')
class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();

  /// Local calendar day, formatted 'YYYY-MM-DD'. A day is a local-time
  /// concept for a daily checklist, so we store the formatted string rather
  /// than a raw instant to avoid timezone/DST comparison bugs.
  TextColumn get date => text()();

  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, date},
  ];
}
