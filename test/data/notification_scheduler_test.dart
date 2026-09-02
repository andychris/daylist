import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/notifications/notification_scheduler.dart';
import 'package:daylist/domain/models/task_category.dart';
import 'package:daylist/domain/models/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_notifications_gateway.dart';

void main() {
  late FakeNotificationsGateway gateway;
  late NotificationScheduler scheduler;

  setUp(() {
    gateway = FakeNotificationsGateway();
    scheduler = NotificationScheduler(gateway);
  });

  TaskRow makeTask({
    int id = 1,
    String title = 'Meditate',
    DateTime? archivedAt,
    int? reminderMinuteOfDay = 9 * 60,
  }) {
    return TaskRow(
      id: id,
      title: title,
      description: null,
      createdAt: DateTime(2026, 1, 1),
      archivedAt: archivedAt,
      sortOrder: 1000,
      category: TaskCategory.other,
      reminderMinuteOfDay: reminderMinuteOfDay,
      dueDate: null,
      recurrenceRule: null,
      priority: TaskPriority.p4,
      projectId: null,
      sectionId: null,
    );
  }

  group('scheduleReminder', () {
    test('schedules an active task with a reminder', () async {
      await scheduler.scheduleReminder(makeTask());
      expect(gateway.scheduled, {1: 9 * 60});
    });

    test('cancels instead of scheduling when reminderMinuteOfDay is null', () async {
      gateway.scheduled[1] = 9 * 60;
      await scheduler.scheduleReminder(makeTask(reminderMinuteOfDay: null));
      expect(gateway.scheduled, isEmpty);
    });

    test('cancels instead of scheduling an archived task', () async {
      gateway.scheduled[1] = 9 * 60;
      await scheduler.scheduleReminder(makeTask(archivedAt: DateTime(2026, 2, 1)));
      expect(gateway.scheduled, isEmpty);
    });
  });

  group('reconcileAll', () {
    test('schedules every active task with a reminder', () async {
      await scheduler.reconcileAll([
        makeTask(id: 1, reminderMinuteOfDay: 9 * 60),
        makeTask(id: 2, reminderMinuteOfDay: 18 * 60),
        makeTask(id: 3, reminderMinuteOfDay: null),
      ]);
      expect(gateway.scheduled, {1: 9 * 60, 2: 18 * 60});
    });

    test('cancels a stale scheduled notification for a task no longer wanting one', () async {
      // Simulates: task 5 was scheduled in a previous run, then its
      // reminder was turned off or it was archived while the app was shut.
      gateway.scheduled[5] = 7 * 60;

      await scheduler.reconcileAll([
        makeTask(id: 1, reminderMinuteOfDay: 9 * 60),
      ]);

      expect(gateway.scheduled, {1: 9 * 60});
    });

    test('cancels a stale notification for a task that was archived', () async {
      gateway.scheduled[1] = 9 * 60;

      await scheduler.reconcileAll([
        makeTask(id: 1, reminderMinuteOfDay: 9 * 60, archivedAt: DateTime(2026, 2, 1)),
      ]);

      expect(gateway.scheduled, isEmpty);
    });
  });
}
