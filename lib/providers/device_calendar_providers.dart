import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar/calendar_event.dart';
import '../data/calendar/device_calendar_source.dart';
import 'date_provider.dart';

final deviceCalendarSourceProvider = Provider<DeviceCalendarSource>((ref) {
  return DeviceCalendarSource();
});

/// Current calendar-permission status, checked (never auto-requested) each
/// time this rebuilds. Call `deviceCalendarSourceProvider`'s
/// `requestPermission()` from an explicit user action, then
/// `ref.invalidate(calendarPermissionProvider)` to refresh this.
final calendarPermissionProvider =
    FutureProvider.autoDispose<CalendarPermissionStatus>((ref) {
      return ref.watch(deviceCalendarSourceProvider).hasPermission();
    });

/// Today's device-calendar events — empty (not an error) until permission
/// is granted, so the UI can distinguish "no events" from "can't check yet".
final todaysEventsProvider = FutureProvider.autoDispose<List<CalendarEvent>>((
  ref,
) async {
  final permission = await ref.watch(calendarPermissionProvider.future);
  if (permission != CalendarPermissionStatus.granted) return const [];

  final today = ref.watch(currentLocalDateProvider);
  return ref.watch(deviceCalendarSourceProvider).eventsForDay(today);
});
