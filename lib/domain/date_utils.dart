/// Formats [date] as a local calendar-day key, 'YYYY-MM-DD'.
String formatLocalDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses a 'YYYY-MM-DD' key back into a local-midnight [DateTime].
DateTime parseLocalDate(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// The local-midnight [DateTime] for "today", used as the boundary for
/// day-existence checks (a task shouldn't count as missed before it existed).
DateTime todayLocalMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Whether a task with lifespan [createdAt]..[archivedAt] was active on
/// [localDate]: created on-or-before that day, and — if archived — archived
/// on-or-after that day. A task archived ON day D still counts D as active;
/// only days strictly after archival are excluded.
bool isTaskActiveOn(DateTime createdAt, DateTime? archivedAt, DateTime localDate) {
  final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
  if (localDate.isBefore(createdDay)) return false;
  if (archivedAt == null) return true;
  final archivedDay = DateTime(archivedAt.year, archivedAt.month, archivedAt.day);
  return !localDate.isAfter(archivedDay);
}

/// Component-wise day arithmetic — safe across DST transitions, unlike
/// `date.add(Duration(days: n))` on a local-time DateTime.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
