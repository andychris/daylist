import 'package:drift/drift.dart';

import '../../domain/date_utils.dart';
import '../../domain/models/checklist_item.dart';
import '../../domain/models/task_lifespan.dart';
import '../database/app_database.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  /// Tasks whose lifespan could overlap [rangeStart, rangeEnd]: created
  /// on-or-before [rangeEnd], and (never archived, or archived on-or-after
  /// [rangeStart]).
  Stream<List<TaskLifespan>> watchTaskLifespans({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final query = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.createdAt.isSmallerOrEqualValue(rangeEnd) &
            (t.archivedAt.isNull() |
                t.archivedAt.isBiggerOrEqualValue(rangeStart)),
      );

    return query.watch().map(
      (rows) => rows
          .map(
            (r) => TaskLifespan(
              id: r.id,
              createdAt: r.createdAt,
              archivedAt: r.archivedAt,
            ),
          )
          .toList(),
    );
  }

  /// {'YYYY-MM-DD': completedCount} for dates in [rangeStart, rangeEnd]. A
  /// completion row only ever exists for a task active that day, so a plain
  /// per-date count needs no join against task lifespans.
  Stream<Map<String, int>> watchCompletionCounts({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final startKey = formatLocalDate(rangeStart);
    final endKey = formatLocalDate(rangeEnd);

    final dateColumn = _db.taskCompletions.date;
    final countColumn = _db.taskCompletions.date.count();

    final query = _db.selectOnly(_db.taskCompletions)
      ..addColumns([dateColumn, countColumn])
      ..where(dateColumn.isBetweenValues(startKey, endKey))
      ..groupBy([dateColumn]);

    return query.watch().map((rows) {
      return {
        for (final row in rows) row.read(dateColumn)!: row.read(countColumn)!,
      };
    });
  }

  /// That day's active tasks + done state, for the day-detail view. Filters
  /// via [isTaskActiveOn] rather than `archivedAt.isNull()` — a task
  /// archived after the viewed day must still show for that day.
  Stream<List<ChecklistItem>> watchChecklistForHistoricalDate(
    DateTime localDate,
  ) {
    final dateKey = formatLocalDate(localDate);

    final query = _db.select(_db.tasks).join([
      leftOuterJoin(
        _db.taskCompletions,
        _db.taskCompletions.taskId.equalsExp(_db.tasks.id) &
            _db.taskCompletions.date.equals(dateKey),
      ),
    ]);

    return query.watch().map((rows) {
      final items = rows
          .where((row) {
            final task = row.readTable(_db.tasks);
            return isTaskActiveOn(task.createdAt, task.archivedAt, localDate);
          })
          .map((row) {
            final task = row.readTable(_db.tasks);
            final completion = row.readTableOrNull(_db.taskCompletions);
            return ChecklistItem(
              id: task.id,
              title: task.title,
              isDoneToday: completion != null,
              sortOrder: task.sortOrder,
            );
          })
          .toList();

      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return items;
    });
  }
}
