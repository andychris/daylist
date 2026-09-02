import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_ids.dart';
import 'notification_background_handler.dart';
import 'notifications_gateway.dart';

const _reminderChannelId = 'daily_reminders';
const _reminderChannelName = 'Daily reminders';

const _reminderActions = [
  AndroidNotificationAction(completeActionId, 'Complete'),
  AndroidNotificationAction(snoozeActionId, 'Snooze 1h'),
];

class FlutterLocalNotificationsGateway implements NotificationsGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      // Foreground taps (app open or backgrounded) and background taps
      // (app force-stopped) both run the same handler — it opens its own
      // short-lived database connection either way, so which isolate it
      // runs on doesn't matter to it.
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundResponseHandler,
    );

    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final androidPlugin = _androidPlugin;
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) return true;
    final granted = await androidPlugin.requestExactAlarmsPermission();
    return granted ?? true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minuteOfDay,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          actions: _reminderActions,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int minuteOfDay,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    while (when.weekday != weekday || when.isBefore(now)) {
      when = when.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          actions: _reminderActions,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    await initialize();

    final scheduledDate = tz.TZDateTime.from(at, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          actions: _reminderActions,
        ),
      ),
      // No matchDateTimeComponents -> fires exactly once. Exact (not
      // inexact) so a specific-time due-date reminder or a snooze
      // actually fires when it says it will, not in some later batched
      // window — requires the exact-alarm permission on Android 12+ (see
      // requestExactAlarmPermission).
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toSet();
  }
}

@visibleForTesting
void handleNotificationResponse(NotificationResponse response) {
  handleNotificationAction(response.actionId, response.id);
}
