import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/repositories/checklist_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChecklistRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ChecklistRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  final today = DateTime(2026, 3, 5);

  test('adding tasks assigns increasing sortOrder', () async {
    await repository.addTask('Meditate');
    await repository.addTask('Read');

    final tasks = await db.select(db.tasks).get();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    expect(tasks.map((t) => t.title), ['Meditate', 'Read']);
    expect(tasks[1].sortOrder, greaterThan(tasks[0].sortOrder));
  });

  test('ignores blank titles', () async {
    await repository.addTask('   ');
    final tasks = await db.select(db.tasks).get();
    expect(tasks, isEmpty);
  });

  test('toggling on then off leaves no completion row', () async {
    await repository.addTask('Meditate');
    final task = (await db.select(db.tasks).get()).single;

    await repository.toggleCompletion(
      taskId: task.id,
      localDate: today,
      isCurrentlyDone: false,
    );
    var completions = await db.select(db.taskCompletions).get();
    expect(completions, hasLength(1));

    await repository.toggleCompletion(
      taskId: task.id,
      localDate: today,
      isCurrentlyDone: true,
    );
    completions = await db.select(db.taskCompletions).get();
    expect(completions, isEmpty);
  });

  test('double toggle-on does not violate the unique key', () async {
    await repository.addTask('Meditate');
    final task = (await db.select(db.tasks).get()).single;

    await repository.toggleCompletion(
      taskId: task.id,
      localDate: today,
      isCurrentlyDone: false,
    );
    // Second call still says isCurrentlyDone: false (e.g. a race from a
    // double-tap); insertOrIgnore must not throw on the unique key.
    await repository.toggleCompletion(
      taskId: task.id,
      localDate: today,
      isCurrentlyDone: false,
    );

    final completions = await db.select(db.taskCompletions).get();
    expect(completions, hasLength(1));
  });

  test('archiveTask removes from active watch but keeps history', () async {
    await repository.addTask('Meditate');
    final task = (await db.select(db.tasks).get()).single;
    await repository.toggleCompletion(
      taskId: task.id,
      localDate: today,
      isCurrentlyDone: false,
    );

    await repository.archiveTask(task.id);

    final active = await repository.watchChecklistForDate(today).first;
    expect(active, isEmpty);

    final history = await db.select(db.taskCompletions).get();
    expect(history, hasLength(1));
  });

  test('watchChecklistForDate only marks the queried date as done', () async {
    await repository.addTask('Meditate');
    final task = (await db.select(db.tasks).get()).single;

    await repository.toggleCompletion(
      taskId: task.id,
      localDate: today,
      isCurrentlyDone: false,
    );

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayItems = await repository
        .watchChecklistForDate(yesterday)
        .first;
    expect(yesterdayItems.single.isDoneToday, isFalse);

    final todayItems = await repository.watchChecklistForDate(today).first;
    expect(todayItems.single.isDoneToday, isTrue);
  });
}
