import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notifications_gateway.dart';

const _reminderChannelId = 'daily_reminders';
const _reminderChannelName = 'Daily reminders';

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
    );

    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

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
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
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
