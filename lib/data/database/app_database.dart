import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/task_category.dart';
import 'converters/task_category_converter.dart';
import 'tables/task_completions_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, TaskCompletions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.category);
        await m.addColumn(tasks, tasks.reminderMinuteOfDay);
      }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'daylist');
}
