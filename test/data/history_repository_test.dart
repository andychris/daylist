import 'package:async/async.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/repositories/history_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = HistoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // These tests predate due dates/recurrence and exercise lifespan
  // (created/archived window) logic only, so every inserted task recurs
  // daily by default — matching the pre-migration "habit" behavior these
  // fixtures were written to represent.
  Future<int> insertTask({
    required DateTime createdAt,
    DateTime? archivedAt,
    String title = 'Task',
  }) {
    return db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: title,
            sortOrder: 0,
            createdAt: Value(createdAt),
            archivedAt: Value(archivedAt),
            recurrenceRule: const Value('daily'),
          ),
        );
  }

  group('watchTaskLifespans', () {
    test('includes a task created before the range that was never archived', () async {
      await insertTask(createdAt: DateTime(2026, 1, 1));

      final lifespans = await repository
          .watchTaskLifespans(
            rangeStart: DateTime(2026, 3, 1),
            rangeEnd: DateTime(2026, 3, 31),
          )
          .first;

      expect(lifespans, hasLength(1));
    });

    test('excludes a task archived before the range', () async {
      await insertTask(
        createdAt: DateTime(2026, 1, 1),
        archivedAt: DateTime(2026, 2, 1),
      );

      final lifespans = await repository
          .watchTaskLifespans(
            rangeStart: DateTime(2026, 3, 1),
            rangeEnd: DateTime(2026, 3, 31),
          )
          .first;

      expect(lifespans, isEmpty);
    });

    test('excludes a task created after the range', () async {
      await insertTask(createdAt: DateTime(2026, 4, 1));

      final lifespans = await repository
          .watchTaskLifespans(
            rangeStart: DateTime(2026, 3, 1),
            rangeEnd: DateTime(2026, 3, 31),
          )
          .first;

      expect(lifespans, isEmpty);
    });

    test('re-emits when a task is inserted', () async {
      final queue = StreamQueue(
        repository.watchTaskLifespans(
          rangeStart: DateTime(2026, 3, 1),
          rangeEnd: DateTime(2026, 3, 31),
        ),
      );

      expect(await queue.next, isEmpty);
      await insertTask(createdAt: DateTime(2026, 3, 5));
      expect(await queue.next, hasLength(1));
      await queue.cancel();
    });
  });

  group('watchCompletionCounts', () {
    test('counts completions per date within range', () async {
      final taskId1 = await insertTask(createdAt: DateTime(2026, 3, 1));
      final taskId2 = await insertTask(createdAt: DateTime(2026, 3, 1));

      await db
          .into(db.taskCompletions)
          .insert(
            TaskCompletionsCompanion.insert(
              taskId: taskId1,
              date: '2026-03-05',
            ),
          );
      await db
          .into(db.taskCompletions)
          .insert(
            TaskCompletionsCompanion.insert(
              taskId: taskId2,
              date: '2026-03-05',
            ),
          );
      await db
          .into(db.taskCompletions)
          .insert(
            TaskCompletionsCompanion.insert(
              taskId: taskId1,
              date: '2026-03-06',
            ),
          );

      final counts = await repository
          .watchCompletionCounts(
            rangeStart: DateTime(2026, 3, 1),
            rangeEnd: DateTime(2026, 3, 31),
          )
          .first;

      expect(counts, {'2026-03-05': 2, '2026-03-06': 1});
    });

    test('excludes completions outside the range', () async {
      final taskId = await insertTask(createdAt: DateTime(2026, 1, 1));
      await db
          .into(db.taskCompletions)
          .insert(
            TaskCompletionsCompanion.insert(taskId: taskId, date: '2026-02-01'),
          );

      final counts = await repository
          .watchCompletionCounts(
            rangeStart: DateTime(2026, 3, 1),
            rangeEnd: DateTime(2026, 3, 31),
          )
          .first;

      expect(counts, isEmpty);
    });
  });

  group('watchChecklistForHistoricalDate', () {
    test('shows a task that was later archived if it was active that day', () async {
      final taskId = await insertTask(
        createdAt: DateTime(2026, 3, 1),
        archivedAt: DateTime(2026, 3, 20),
        title: 'Old task',
      );
      await db
          .into(db.taskCompletions)
          .insert(
            TaskCompletionsCompanion.insert(taskId: taskId, date: '2026-03-10'),
          );

      final items = await repository
          .watchChecklistForHistoricalDate(DateTime(2026, 3, 10))
          .first;

      expect(items, hasLength(1));
      expect(items.single.title, 'Old task');
      expect(items.single.isDoneToday, isTrue);
    });

    test('hides a task on a day before it was created', () async {
      await insertTask(createdAt: DateTime(2026, 3, 15));

      final items = await repository
          .watchChecklistForHistoricalDate(DateTime(2026, 3, 10))
          .first;

      expect(items, isEmpty);
    });

    test('hides a task on a day after it was archived', () async {
      await insertTask(
        createdAt: DateTime(2026, 3, 1),
        archivedAt: DateTime(2026, 3, 10),
      );

      final items = await repository
          .watchChecklistForHistoricalDate(DateTime(2026, 3, 11))
          .first;

      expect(items, isEmpty);
    });
  });
}
