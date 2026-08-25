import 'package:device_calendar_plus/device_calendar_plus.dart';

import 'calendar_event.dart';

/// Read-only access to the device's calendar events — deliberately outside
/// the app's recurring-checklist domain/repositories (see the "Today's
/// events" panel this backs: events never become checklist tasks).
class DeviceCalendarSource {
  /// Current permission status, without prompting.
  Future<CalendarPermissionStatus> hasPermission() =>
      DeviceCalendar.instance.hasPermissions();

  /// Shows the system permission dialog if not already decided.
  Future<CalendarPermissionStatus> requestPermission() =>
      DeviceCalendar.instance.requestPermissions();

  Future<List<CalendarEvent>> eventsForDay(DateTime localDay) async {
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    final end = start.add(const Duration(days: 1));

    final events = await DeviceCalendar.instance.listEvents(start, end);
    final mapped = events
        .map(
          (e) => CalendarEvent(
            title: e.title,
            startTime: e.startDate,
            endTime: e.endDate,
            isAllDay: e.isAllDay,
          ),
        )
        .toList();
    mapped.sort((a, b) => a.startTime.compareTo(b.startTime));
    return mapped;
  }
}
