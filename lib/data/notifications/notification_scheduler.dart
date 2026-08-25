import '../database/app_database.dart';
import 'notifications_gateway.dart';

const _notificationTitle = 'Daylist';

/// Keeps scheduled notifications in sync with tasks' reminder settings.
class NotificationScheduler {
  NotificationScheduler(this._gateway);

  final NotificationsGateway _gateway;

  /// Schedules (or cancels, if the task has no reminder or is archived) the
  /// notification for [task]. A task's Drift row `id` doubles as its stable
  /// notification id.
  Future<void> scheduleReminder(TaskRow task) async {
    if (task.reminderMinuteOfDay == null || task.archivedAt != null) {
      await cancelReminder(task.id);
      return;
    }
    await _gateway.scheduleDaily(
      id: task.id,
      title: _notificationTitle,
      body: task.title,
      minuteOfDay: task.reminderMinuteOfDay!,
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
