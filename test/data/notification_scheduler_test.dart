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
    DateTime? dueDate,
    String? recurrenceRule,
    DateTime? createdAt,
  }) {
    return TaskRow(
      id: id,
      title: title,
      description: null,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      archivedAt: archivedAt,
      sortOrder: 1000,
      category: TaskCategory.other,
      reminderMinuteOfDay: reminderMinuteOfDay,
      dueDate: dueDate,
      recurrenceRule: recurrenceRule,
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

  group('scheduleReminder dispatch by recurrence', () {
    test('a one-off task with a due date schedules a one-shot at that date+time', () async {
      await scheduler.scheduleReminder(
        makeTask(dueDate: DateTime(2026, 3, 15), reminderMinuteOfDay: 16 * 60),
      );
      expect(gateway.scheduledOnce, {1: DateTime(2026, 3, 15, 16, 0)});
      expect(gateway.scheduled, isEmpty);
    });

    test('recurrenceRule "daily" schedules a native daily repeat', () async {
      await scheduler.scheduleReminder(makeTask(recurrenceRule: 'daily'));
      expect(gateway.scheduled, {1: 9 * 60});
      expect(gateway.scheduledOnce, isEmpty);
    });

    test('recurrenceRule "weekly:X" schedules a native weekly repeat', () async {
      await scheduler.scheduleReminder(makeTask(recurrenceRule: 'weekly:MON'));
      expect(gateway.scheduledWeekly, {
        1: (weekday: DateTime.monday, minuteOfDay: 9 * 60),
      });
    });

    test('recurrenceRule "weekdays" schedules a one-shot for the next matching day', () async {
      // Created on a Sunday; "weekdays" next matches Monday.
      await scheduler.scheduleReminder(
        makeTask(
          recurrenceRule: 'weekdays',
          createdAt: DateTime(2026, 3, 1),
          reminderMinuteOfDay: 9 * 60,
        ),
      );
      expect(gateway.scheduledOnce.keys, [1]);
      expect(gateway.scheduled, isEmpty);
      expect(gateway.scheduledWeekly, isEmpty);
    });
  });

  group('rescheduleNextOccurrence', () {
    test('is a no-op for a "daily" rule (already repeats natively)', () async {
      final task = makeTask(recurrenceRule: 'daily');
      await scheduler.rescheduleNextOccurrence(task, after: DateTime(2026, 3, 15));
      expect(gateway.scheduledOnce, isEmpty);
    });

    test('is a no-op for a "weekly:X" rule (already repeats natively)', () async {
      final task = makeTask(recurrenceRule: 'weekly:MON');
      await scheduler.rescheduleNextOccurrence(task, after: DateTime(2026, 3, 15));
      expect(gateway.scheduledOnce, isEmpty);
    });

    test('schedules the next occurrence strictly after the given day for "every:N"', () async {
      final task = makeTask(
        recurrenceRule: 'every:2',
        createdAt: DateTime(2026, 3, 10),
      );
      await scheduler.rescheduleNextOccurrence(task, after: DateTime(2026, 3, 14));
      // every:2 from Mar 10 matches 10,12,14,16... "after" is Mar 14, so
      // the next occurrence strictly after it is Mar 16.
      expect(gateway.scheduledOnce, {1: DateTime(2026, 3, 16, 9, 0)});
    });

    test('is a no-op for a non-recurring task', () async {
      final task = makeTask(dueDate: DateTime(2026, 3, 15));
      await scheduler.rescheduleNextOccurrence(task, after: DateTime(2026, 3, 15));
      expect(gateway.scheduledOnce, isEmpty);
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
