/// A read-only view of a device calendar event, deliberately outside the
/// app's recurring-checklist domain — see device_calendar_source.dart.
class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
  });

  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
}
