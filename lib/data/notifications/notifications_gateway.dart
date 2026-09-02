/// Thin boundary over the platform notification APIs, so scheduling logic
/// can be tested against a fake without touching real platform channels.
abstract class NotificationsGateway {
  /// One-time setup (timezone data, plugin init). Safe to call repeatedly.
  Future<void> initialize();

  /// Prompts for notification permission if not already decided. Returns
  /// whether permission is granted.
  Future<bool> requestPermission();

  /// Prompts for the exact-alarm permission Android 12+ requires for
  /// [scheduleOnce]/[scheduleWeekly] to fire at their exact time rather
  /// than a batched, possibly-late window. Returns true immediately on
  /// platforms/versions that don't need it.
  Future<bool> requestExactAlarmPermission();

  /// Schedules a notification that repeats daily at [minuteOfDay] (minutes
  /// since local midnight), replacing any existing schedule for [id].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minuteOfDay,
  });

  /// Schedules a notification that repeats weekly on [weekday]
  /// (`DateTime.monday`..`DateTime.sunday`) at [minuteOfDay], replacing any
  /// existing schedule for [id].
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int minuteOfDay,
  });

  /// Schedules a single one-shot notification at the exact moment [at],
  /// replacing any existing schedule for [id]. Used for a one-off task's
  /// due-date reminder, a snooze, and recurrence rules with no native
  /// repeat primitive (`weekdays`, `monthly:D`, `every:N`) — see
  /// `NotificationScheduler.rescheduleNextOccurrence`.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });

  /// Cancels a scheduled notification, if any. A no-op if [id] has none.
  Future<void> cancel(int id);

  /// IDs with a currently-scheduled notification.
  Future<Set<int>> pendingIds();
}
