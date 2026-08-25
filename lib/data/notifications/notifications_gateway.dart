/// Thin boundary over the platform notification APIs, so scheduling logic
/// can be tested against a fake without touching real platform channels.
abstract class NotificationsGateway {
  /// One-time setup (timezone data, plugin init). Safe to call repeatedly.
  Future<void> initialize();

  /// Prompts for notification permission if not already decided. Returns
  /// whether permission is granted.
  Future<bool> requestPermission();

  /// Schedules a notification that repeats daily at [minuteOfDay] (minutes
  /// since local midnight), replacing any existing schedule for [id].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minuteOfDay,
  });

  /// Cancels a scheduled notification, if any. A no-op if [id] has none.
  Future<void> cancel(int id);

  /// IDs with a currently-scheduled notification.
  Future<Set<int>> pendingIds();
}
