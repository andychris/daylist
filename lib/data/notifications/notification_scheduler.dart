import '../../domain/due_logic.dart';
import '../database/app_database.dart';
import 'notifications_gateway.dart';

const _notificationTitle = 'daylist';

const _weekdayCodes = {
  'MON': DateTime.monday,
  'TUE': DateTime.tuesday,
  'WED': DateTime.wednesday,
  'THU': DateTime.thursday,
  'FRI': DateTime.friday,
  'SAT': DateTime.saturday,
  'SUN': DateTime.sunday,
};

/// Keeps scheduled notifications in sync with tasks' reminder settings.
class NotificationScheduler {
  NotificationScheduler(this._gateway);

  final NotificationsGateway _gateway;

  /// Schedules (or cancels, if the task has no reminder or is archived) the
  /// notification for [task]. A task's Drift row `id` doubles as its stable
  /// notification id.
  ///
  /// Dispatches on the task's recurrence, since only `daily` and
  /// `weekly:X` have a native "repeat on its own" primitive:
  /// - No recurrence, no due date: a plain repeating daily reminder (the
  ///   original, simplest feature — a habit with just a reminder time).
  /// - No recurrence, a due date: a one-shot exact alarm at that date+time.
  /// - `daily` / `weekly:X`: scheduled to repeat natively.
  /// - Anything else (`weekdays`, `monthly:D`, `every:N`): a one-shot
  ///   alarm for the next matching day — kept going by
  ///   [rescheduleNextOccurrence] once that alarm fires/is acted on.
  Future<void> scheduleReminder(TaskRow task) async {
    if (task.reminderMinuteOfDay == null || task.archivedAt != null) {
      await cancelReminder(task.id);
      return;
    }

    final rule = task.recurrenceRule;
    final minuteOfDay = task.reminderMinuteOfDay!;

    if (rule == null) {
      if (task.dueDate == null) {
        await _gateway.scheduleDaily(
          id: task.id,
          title: _notificationTitle,
          body: task.title,
          minuteOfDay: minuteOfDay,
        );
      } else {
        await _gateway.scheduleOnce(
          id: task.id,
          title: _notificationTitle,
          body: task.title,
          at: _atTime(task.dueDate!, minuteOfDay),
        );
      }
      return;
    }

    if (rule == 'daily') {
      await _gateway.scheduleDaily(
        id: task.id,
        title: _notificationTitle,
        body: task.title,
        minuteOfDay: minuteOfDay,
      );
      return;
    }

    final weekday = _weekdayFromRule(rule);
    if (weekday != null) {
      await _gateway.scheduleWeekly(
        id: task.id,
        title: _notificationTitle,
        body: task.title,
        weekday: weekday,
        minuteOfDay: minuteOfDay,
      );
      return;
    }

    final today = DateTime.now();
    final next = nextOccurrenceOnOrAfter(
      rule,
      DateTime(today.year, today.month, today.day),
      task.createdAt,
    );
    if (next == null) {
      await cancelReminder(task.id);
      return;
    }
    await _gateway.scheduleOnce(
      id: task.id,
      title: _notificationTitle,
      body: task.title,
      at: _atTime(next, minuteOfDay),
    );
  }

  /// Re-schedules [task]'s reminder for its next occurrence strictly after
  /// [after] (typically "now") — call once a one-shot-style recurring
  /// reminder (`weekdays`/`monthly:D`/`every:N`) has fired or its task was
  /// completed from the notification, so the *next* due day gets a fresh
  /// alarm. A no-op for `daily`/`weekly:X` (already repeat natively) or a
  /// task with no reminder/recurrence.
  Future<void> rescheduleNextOccurrence(TaskRow task, {required DateTime after}) async {
    final rule = task.recurrenceRule;
    if (task.reminderMinuteOfDay == null || task.archivedAt != null || rule == null) {
      return;
    }
    if (rule == 'daily' || _weekdayFromRule(rule) != null) return;

    final tomorrow = DateTime(
      after.year,
      after.month,
      after.day,
    ).add(const Duration(days: 1));
    final next = nextOccurrenceOnOrAfter(rule, tomorrow, task.createdAt);
    if (next == null) return;

    await _gateway.scheduleOnce(
      id: task.id,
      title: _notificationTitle,
      body: task.title,
      at: _atTime(next, task.reminderMinuteOfDay!),
    );
  }

  Future<void> cancelReminder(int taskId) => _gateway.cancel(taskId);

  /// Reconciles all scheduled notifications against [allTasks]' current
  /// reminder settings — cancels anything scheduled that shouldn't be
  /// (a task archived or edited while the app wasn't running), then
  /// (re)schedules everything that should be. Meant to run once at startup,
  /// since the OS can silently drop scheduled notifications (force-stop,
  /// reinstall, timezone change).
  Future<void> reconcileAll(List<TaskRow> allTasks) async {
    final desired = {
      for (final t in allTasks)
        if (t.archivedAt == null && t.reminderMinuteOfDay != null) t.id,
    };

    final pending = await _gateway.pendingIds();
    for (final staleId in pending.difference(desired)) {
      await _gateway.cancel(staleId);
    }

    for (final task in allTasks) {
      await scheduleReminder(task);
    }
  }
}

int? _weekdayFromRule(String rule) {
  if (!rule.startsWith('weekly:')) return null;
  return _weekdayCodes[rule.substring('weekly:'.length)];
}

DateTime _atTime(DateTime day, int minuteOfDay) {
  return DateTime(day.year, day.month, day.day, minuteOfDay ~/ 60, minuteOfDay % 60);
}
