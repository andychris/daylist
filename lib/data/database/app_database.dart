import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/project_view_type.dart';
import '../../domain/models/task_category.dart';
import '../../domain/models/task_priority.dart';
import 'converters/project_view_type_converter.dart';
import 'converters/task_category_converter.dart';
import 'converters/task_priority_converter.dart';
import 'tables/labels_table.dart';
import 'tables/projects_table.dart';
import 'tables/sections_table.dart';
import 'tables/task_completions_table.dart';
import 'tables/task_labels_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Tasks, TaskCompletions, Projects, Sections, Labels, TaskLabels],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Each block is also gated on `to` (not just `from`) so that
      // testing a single step in isolation — e.g. drift_dev's
      // SchemaVerifier migrating 1 -> 2 without going all the way to the
      // current schemaVersion — doesn't also run later steps.
      if (from < 2 && to >= 2) {
        await m.addColumn(tasks, tasks.category);
        await m.addColumn(tasks, tasks.reminderMinuteOfDay);
      }
      if (from < 3 && to >= 3) {
        await m.addColumn(tasks, tasks.description);
        await m.addColumn(tasks, tasks.dueDate);
        await m.addColumn(tasks, tasks.recurrenceRule);
        await m.addColumn(tasks, tasks.priority);
        await m.addColumn(tasks, tasks.projectId);
        await m.addColumn(tasks, tasks.sectionId);
        await m.createTable(projects);
        await m.createTable(sections);
        await m.createTable(labels);
        await m.createTable(taskLabels);
        await _seedDefaultProjectsAndMigrateCategories();
        // Every row that existed before this migration was, under the old
        // model, a habit that recurred every day — preserve that behavior
        // exactly. Rows inserted after this point default to no
        // recurrence (one-off) unless the user explicitly asks for one.
        await (update(
          tasks,
        )..where((t) => t.recurrenceRule.isNull())).write(
          const TasksCompanion(recurrenceRule: Value('daily')),
        );
      }
    },
  );

  /// Seeds one default Project per legacy [TaskCategory] value and points
  /// each existing task's `projectId` at the project matching its old
  /// `category`, so the v3 migration doesn't lose any user categorization
  /// even though the UI moves from fixed categories to user projects.
  Future<void> _seedDefaultProjectsAndMigrateCategories() async {
    const categoryToProjectName = {
      TaskCategory.personal: 'Personal',
      TaskCategory.work: 'Work',
      TaskCategory.health: 'Health',
      TaskCategory.errands: 'Errands',
      TaskCategory.shopping: 'Shopping',
      TaskCategory.other: 'Other',
    };

    final projectIdByCategory = <TaskCategory, int>{};
    var order = 0.0;
    for (final entry in categoryToProjectName.entries) {
      final id = await into(
        projects,
      ).insert(ProjectsCompanion.insert(name: entry.value, sortOrder: order));
      projectIdByCategory[entry.key] = id;
      order += 1000;
    }

    for (final task in await select(tasks).get()) {
      final projectId = projectIdByCategory[task.category];
      if (projectId == null) continue;
      await (update(
        tasks,
      )..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(projectId: Value(projectId)),
      );
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'daylist');
}
