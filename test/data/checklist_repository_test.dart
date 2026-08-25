import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/notifications/notification_scheduler.dart';
import 'package:daylist/data/repositories/checklist_repository.dart';
import 'package:daylist/domain/models/task_category.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_notifications_gateway.dart';

void main() {
  late AppDatabase db;
  late ChecklistRepository repository;
  late FakeNotificationsGateway notificationsGateway;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notificationsGateway = FakeNotificationsGateway();
    repository = ChecklistRepository(
      db,
      NotificationScheduler(notificationsGateway),
    );
  });

  tearDown(() async {
    await db.close();
  });

  final today = DateTime(2026, 3, 5);

  Future<void> addTask(String title, {TaskCategory category = TaskCategory.other}) {
    return repository.addTask(title: title, category: category);
  }

  test('adding tasks assigns increasing sortOrder', () async {
    await addTask('Meditate');
    await addTask('Read');

    final tasks = await db.select(db.tasks).get();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    expect(tasks.map((t) => t.title), ['Meditate', 'Read']);
    expect(tasks[1].sortOrder, greaterThan(tasks[0].sortOrder));
  });

  test('ignores blank titles', () async {
    await addTask('   ');
    final tasks = await db.select(db.tasks).get();
    expect(tasks, isEmpty);
  });

  test('defaults to TaskCategory.other and stores a chosen category', () async {
    await addTask('Meditate');
    await repository.addTask(title: 'Standup', category: TaskCategory.work);

    final tasks = await db.select(db.tasks).get();
    final meditate = tasks.firstWhere((t) => t.title == 'Meditate');
    final standup = tasks.firstWhere((t) => t.title == 'Standup');
    expect(meditate.category, TaskCategory.other);
    expect(standup.category, TaskCategory.work);
  });

  test('stores an optional reminder time and updateTask can change it', () async {
    await repository.addTask(
      title: 'Meditate',
      category: TaskCategory.health,
      reminderMinuteOfDay: 9 * 60,
    );
    final task = (await db.select(db.tasks).get()).single;
    expect(task.reminderMinuteOfDay, 9 * 60);

    await repository.updateTask(taskId: task.id, reminderMinuteOfDay: const Value(null));
    final updated = (await db.select(db.tasks).get()).single;
    expect(updated.reminderMinuteOfDay, isNull);
  });

  test('addTask with a reminder schedules a notification', () async {
    await repository.addTask(
      title: 'Meditate',
      category: TaskCategory.health,
      reminderMinuteOfDay: 9 * 60,
    );
    final task = (await db.select(db.tasks).get()).single;
    expect(notificationsGateway.scheduled, {task.id: 9 * 60});
  });

  test('archiveTask cancels its scheduled notification', () async {
    await repository.addTask(
      title: 'Meditate',
      category: TaskCategory.health,
      reminderMinuteOfDay: 9 * 60,
    );
    final task = (await db.select(db.tasks).get()).single;
    expect(notificationsGateway.scheduled, isNotEmpty);

    await repository.archiveTask(task.id);
    expect(notificationsGateway.scheduled, isEmpty);
  });

  test('updateTask leaves fields unspecified untouched', () async {
    await repository.addTask(title: 'Meditate', category: TaskCategory.health);
    final task = (await db.select(db.tasks).get()).single;

    await repository.updateTask(taskId: task.id, title: 'Meditate daily');

    final updated = (await db.select(db.tasks).get()).single;
    expect(updated.title, 'Meditate daily');
    expect(updated.category, TaskCategory.health);
  });

  test('toggling on then off leaves no completion row', () async {
    await addTask('Meditate');
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
    await addTask('Meditate');
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
    await addTask('Meditate');
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
    await addTask('Meditate');
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
