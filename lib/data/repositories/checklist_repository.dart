import 'package:drift/drift.dart';

import '../../domain/date_utils.dart';
import '../../domain/models/checklist_item.dart';
import '../../domain/models/task_category.dart';
import '../../domain/models/task_priority.dart';
import '../database/app_database.dart';
import '../notifications/notification_scheduler.dart';

class ChecklistRepository {
  ChecklistRepository(this._db, this._notificationScheduler);

  final AppDatabase _db;
  final NotificationScheduler _notificationScheduler;

  /// Streams active tasks joined against today's completion state, sorted
  /// so completed items sink below active ones.
  Stream<List<ChecklistItem>> watchChecklistForDate(DateTime localDate) {
    final dateKey = formatLocalDate(localDate);

    final query = _db.select(_db.tasks).join([
      leftOuterJoin(
        _db.taskCompletions,
        _db.taskCompletions.taskId.equalsExp(_db.tasks.id) &
            _db.taskCompletions.date.equals(dateKey),
      ),
    ])..where(_db.tasks.archivedAt.isNull());

    return query.watch().map((rows) {
      final items = rows.map((row) {
        final task = row.readTable(_db.tasks);
        final completion = row.readTableOrNull(_db.taskCompletions);
        return ChecklistItem(
          id: task.id,
          title: task.title,
          isDoneToday: completion != null,
          sortOrder: task.sortOrder,
          category: task.category,
          reminderMinuteOfDay: task.reminderMinuteOfDay,
          priority: task.priority,
          projectId: task.projectId,
          dueDate: task.dueDate,
          recurrenceRule: task.recurrenceRule,
        );
      }).toList();

      items.sort((a, b) {
        if (a.isDoneToday != b.isDoneToday) {
          return a.isDoneToday ? 1 : -1;
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });
      return items;
    });
  }

  Future<void> addTask({
    required String title,
    TaskCategory category = TaskCategory.other,
    int? reminderMinuteOfDay,
    TaskPriority priority = TaskPriority.p4,
    int? projectId,
    DateTime? dueDate,
    String? recurrenceRule,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final id = await _db.transaction(() async {
      final maxOrder = await (_db.selectOnly(_db.tasks)
            ..addColumns([_db.tasks.sortOrder.max()]))
          .map((row) => row.read(_db.tasks.sortOrder.max()))
          .getSingleOrNull();

      return _db
          .into(_db.tasks)
          .insert(
            TasksCompanion.insert(
              title: trimmed,
              sortOrder: (maxOrder ?? 0) + 1000,
              category: Value(category),
              reminderMinuteOfDay: Value(reminderMinuteOfDay),
              priority: Value(priority),
              projectId: Value(projectId),
              dueDate: Value(dueDate),
              recurrenceRule: Value(recurrenceRule),
            ),
          );
    });

    if (reminderMinuteOfDay != null) {
      final task = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(id))).getSingle();
      await _notificationScheduler.scheduleReminder(task);
    }
  }

  /// Updates an existing task. Omitted parameters leave that field
  /// unchanged; pass e.g. [reminderMinuteOfDay] as `Value(null)` to
  /// explicitly clear it (vs. `Value.absent()`, the default, to leave it
  /// as-is).
  Future<void> updateTask({
    required int taskId,
    String? title,
    TaskCategory? category,
    Value<int?> reminderMinuteOfDay = const Value.absent(),
    TaskPriority? priority,
    Value<int?> projectId = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
  }) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        title: title != null ? Value(title.trim()) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        reminderMinuteOfDay: reminderMinuteOfDay,
        priority: priority != null ? Value(priority) : const Value.absent(),
        projectId: projectId,
        dueDate: dueDate,
        recurrenceRule: recurrenceRule,
      ),
    );

    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    await _notificationScheduler.scheduleReminder(task);
  }

  Future<void> toggleCompletion({
    required int taskId,
    required DateTime localDate,
    required bool isCurrentlyDone,
  }) async {
    final dateKey = formatLocalDate(localDate);

    if (isCurrentlyDone) {
      await (_db.delete(_db.taskCompletions)..where(
            (c) => c.taskId.equals(taskId) & c.date.equals(dateKey),
          ))
          .go();
    } else {
      await _db
          .into(_db.taskCompletions)
          .insert(
            TaskCompletionsCompanion.insert(taskId: taskId, date: dateKey),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<void> archiveTask(int taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(archivedAt: Value(DateTime.now())),
    );
    await _notificationScheduler.cancelReminder(taskId);
  }

  Future<void> restoreTask(int taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(archivedAt: Value(null)),
    );

    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    if (task.reminderMinuteOfDay != null) {
      await _notificationScheduler.scheduleReminder(task);
    }
  }
}
