import '../models/task_priority.dart';
import 'parsed_quick_add_result.dart';

const _weekdayNames = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const _monthNames = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

final _weekdayAlternation = _weekdayNames.join('|');
final _monthAlternation = _monthNames.join('|');
final _monthAbbrevAlternation = _monthNames
    .map((m) => m.substring(0, 3))
    .join('|');

final _priorityPattern = RegExp(r'(?<![A-Za-z0-9])[pP]([1-4])(?![A-Za-z0-9])');
final _projectPattern = RegExp(r'#([A-Za-z0-9_-]+)');
final _labelPattern = RegExp(r'@([A-Za-z0-9_-]+)');

final _everyDayPattern = RegExp(r'\bevery day\b', caseSensitive: false);
final _everyWeekdayPattern = RegExp(r'\bevery weekday\b', caseSensitive: false);
final _everyNDaysPattern = RegExp(
  r'\bevery (\d+) days?\b',
  caseSensitive: false,
);
final _everyMonthOnThePattern = RegExp(
  r'\bevery month on the (\d{1,2})(?:st|nd|rd|th)?\b',
  caseSensitive: false,
);
final _everyWeekdayNamePattern = RegExp(
  '\\bevery ($_weekdayAlternation)\\b',
  caseSensitive: false,
);

final _isoDatePattern = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b');
final _inNDaysPattern = RegExp(r'\bin (\d+) days?\b', caseSensitive: false);
final _relativeWeekdayPattern = RegExp(
  '\\b(next|this)\\s+($_weekdayAlternation)\\b',
  caseSensitive: false,
);
final _bareWeekdayPattern = RegExp(
  '\\b($_weekdayAlternation)\\b',
  caseSensitive: false,
);
final _monthDayPattern = RegExp(
  '\\b($_monthAlternation)\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(\\d{4}))?\\b',
  caseSensitive: false,
);
final _monthDayAbbrevPattern = RegExp(
  '\\b($_monthAbbrevAlternation)\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(\\d{4}))?\\b',
  caseSensitive: false,
);

final _timePattern = RegExp(
  r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
  caseSensitive: false,
);
final _time24Pattern = RegExp(r'\b(?:at\s+)?([01]?\d|2[0-3]):([0-5]\d)\b');

final _todayPattern = RegExp(r'\btoday\b', caseSensitive: false);
final _tomorrowPattern = RegExp(r'\btomorrow\b', caseSensitive: false);
final _yesterdayPattern = RegExp(r'\byesterday\b', caseSensitive: false);

/// A half-open `[start, end)` character range in quick-add input text,
/// framework-free so this stays usable from `domain/` (a UI layer turns it
/// into e.g. a `TextSpan` for inline highlighting).
typedef HighlightRange = ({int start, int end});

/// Every substring of [text] recognized by [parseQuickAddInput] — for a
/// quick-add text field's live token highlighting. Best-effort: unlike the
/// parser itself, this doesn't need to resolve which of several
/// overlapping candidate phrases "wins", since it's purely visual.
List<HighlightRange> findHighlightRanges(String text) {
  final ranges = <HighlightRange>[];
  void addAll(RegExp pattern) {
    for (final match in pattern.allMatches(text)) {
      ranges.add((start: match.start, end: match.end));
    }
  }

  addAll(_priorityPattern);
  addAll(_projectPattern);
  addAll(_labelPattern);
  addAll(_everyMonthOnThePattern);
  addAll(_everyNDaysPattern);
  addAll(_everyWeekdayPattern);
  addAll(_everyDayPattern);
  addAll(_everyWeekdayNamePattern);
  addAll(_todayPattern);
  addAll(_tomorrowPattern);
  addAll(_yesterdayPattern);
  addAll(_inNDaysPattern);
  addAll(_isoDatePattern);
  addAll(_relativeWeekdayPattern);
  addAll(_monthDayPattern);
  addAll(_monthDayAbbrevPattern);
  addAll(_bareWeekdayPattern);
  addAll(_timePattern);
  addAll(_time24Pattern);
  return ranges;
}

/// Parses Todoist-style quick-add text into a title plus structured
/// metadata. Pure and synchronous — [now] anchors relative phrases like
/// "today"/"next monday" so this stays testable without a real clock.
///
/// Recognizes (case-insensitive): relative dates (today/tomorrow/
/// yesterday/next|this WEEKDAY/bare WEEKDAY/"in N days"), specific dates
/// ("Oct 15", "October 15th 2027", `YYYY-MM-DD`), a trailing time ("4pm",
/// "10:30am", "16:30"), recurrence ("every day", "every weekday", "every
/// MONDAY", "every N days", "every month on the 1st"), `p1`-`p4`,
/// `#Project`, and any number of `@Label` tags.
ParsedQuickAddResult parseQuickAddInput(String input, {required DateTime now}) {
  var text = input;

  final priority = _extractPriority(text);
  text = priority.remaining;

  final project = _extractFirst(text, _projectPattern);
  text = project.remaining;

  final labels = <String>[
    for (final match in _labelPattern.allMatches(text)) match.group(1)!,
  ];
  text = text.replaceAll(_labelPattern, ' ');

  final recurrence = _extractRecurrence(text);
  text = recurrence.remaining;

  DateTime? dueDate;
  if (recurrence.rule == null) {
    final date = _extractDate(text, now);
    dueDate = date.date;
    text = date.remaining;
  }

  final time = _extractTime(text);
  text = time.remaining;
  // A bare time with no date/recurrence otherwise resolved implies today
  // (matches the common "add a task due at 4pm" shorthand).
  if (time.minuteOfDay != null && dueDate == null && recurrence.rule == null) {
    dueDate = DateTime(now.year, now.month, now.day);
  }

  final cleanedTitle = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  return ParsedQuickAddResult(
    cleanedTitle: cleanedTitle,
    dueDate: dueDate,
    dueTimeMinuteOfDay: time.minuteOfDay,
    recurrenceRule: recurrence.rule,
    priority: priority.value,
    projectName: project.value,
    labelNames: labels,
  );
}

class _ExtractResult<T> {
  const _ExtractResult(this.value, this.remaining);
  final T value;
  final String remaining;
}

typedef _PriorityExtract = _ExtractResult<TaskPriority?>;

_PriorityExtract _extractPriority(String text) {
  final match = _priorityPattern.firstMatch(text);
  if (match == null) return _PriorityExtract(null, text);
  final priority = TaskPriority.values[int.parse(match.group(1)!) - 1];
  return _PriorityExtract(priority, _remove(text, match));
}

_ExtractResult<String?> _extractFirst(String text, RegExp pattern) {
  final match = pattern.firstMatch(text);
  if (match == null) return _ExtractResult(null, text);
  return _ExtractResult(match.group(1), _remove(text, match));
}

class _RecurrenceResult {
  const _RecurrenceResult(this.rule, this.remaining);
  final String? rule;
  final String remaining;
}

_RecurrenceResult _extractRecurrence(String text) {
  var match = _everyMonthOnThePattern.firstMatch(text);
  if (match != null) {
    return _RecurrenceResult('monthly:${match.group(1)}', _remove(text, match));
  }

  match = _everyNDaysPattern.firstMatch(text);
  if (match != null) {
    return _RecurrenceResult('every:${match.group(1)}', _remove(text, match));
  }

  match = _everyWeekdayPattern.firstMatch(text);
  if (match != null) {
    return _RecurrenceResult('weekdays', _remove(text, match));
  }

  match = _everyDayPattern.firstMatch(text);
  if (match != null) {
    return _RecurrenceResult('daily', _remove(text, match));
  }

  match = _everyWeekdayNamePattern.firstMatch(text);
  if (match != null) {
    final code = _weekdayCode(match.group(1)!);
    return _RecurrenceResult('weekly:$code', _remove(text, match));
  }

  return _RecurrenceResult(null, text);
}

class _DateResult {
  const _DateResult(this.date, this.remaining);
  final DateTime? date;
  final String remaining;
}

_DateResult _extractDate(String text, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  final todayMatch = _todayPattern.firstMatch(text);
  if (todayMatch != null) {
    return _DateResult(today, _remove(text, todayMatch));
  }

  final tomorrowMatch = _tomorrowPattern.firstMatch(text);
  if (tomorrowMatch != null) {
    return _DateResult(
      today.add(const Duration(days: 1)),
      _remove(text, tomorrowMatch),
    );
  }

  final yesterdayMatch = _yesterdayPattern.firstMatch(text);
  if (yesterdayMatch != null) {
    return _DateResult(
      today.subtract(const Duration(days: 1)),
      _remove(text, yesterdayMatch),
    );
  }

  final inDaysMatch = _inNDaysPattern.firstMatch(text);
  if (inDaysMatch != null) {
    final n = int.parse(inDaysMatch.group(1)!);
    return _DateResult(
      today.add(Duration(days: n)),
      _remove(text, inDaysMatch),
    );
  }

  final isoMatch = _isoDatePattern.firstMatch(text);
  if (isoMatch != null) {
    final date = DateTime(
      int.parse(isoMatch.group(1)!),
      int.parse(isoMatch.group(2)!),
      int.parse(isoMatch.group(3)!),
    );
    return _DateResult(date, _remove(text, isoMatch));
  }

  final relativeWeekdayMatch = _relativeWeekdayPattern.firstMatch(text);
  if (relativeWeekdayMatch != null) {
    final isNext = relativeWeekdayMatch.group(1)!.toLowerCase() == 'next';
    final targetWeekday = _weekdayNames.indexOf(
      relativeWeekdayMatch.group(2)!.toLowerCase(),
    ); // 0 = Monday
    final date = _nextWeekday(today, targetWeekday, skipToday: isNext);
    return _DateResult(date, _remove(text, relativeWeekdayMatch));
  }

  final monthDayMatch = _monthDayPattern.firstMatch(text);
  if (monthDayMatch != null) {
    return _DateResult(
      _resolveMonthDay(monthDayMatch, today, isAbbrev: false),
      _remove(text, monthDayMatch),
    );
  }

  final monthDayAbbrevMatch = _monthDayAbbrevPattern.firstMatch(text);
  if (monthDayAbbrevMatch != null) {
    return _DateResult(
      _resolveMonthDay(monthDayAbbrevMatch, today, isAbbrev: true),
      _remove(text, monthDayAbbrevMatch),
    );
  }

  final bareWeekdayMatch = _bareWeekdayPattern.firstMatch(text);
  if (bareWeekdayMatch != null) {
    final targetWeekday = _weekdayNames.indexOf(
      bareWeekdayMatch.group(1)!.toLowerCase(),
    );
    final date = _nextWeekday(today, targetWeekday, skipToday: false);
    return _DateResult(date, _remove(text, bareWeekdayMatch));
  }

  return _DateResult(null, text);
}

DateTime _resolveMonthDay(
  RegExpMatch match,
  DateTime today, {
  required bool isAbbrev,
}) {
  final monthName = match.group(1)!.toLowerCase();
  final month = isAbbrev
      ? _monthNames.indexWhere((m) => m.startsWith(monthName)) + 1
      : _monthNames.indexOf(monthName) + 1;
  final day = int.parse(match.group(2)!);
  final explicitYear = match.group(3);

  var year = explicitYear != null ? int.parse(explicitYear) : today.year;
  var date = DateTime(year, month, day);
  // No explicit year and the date already passed this year -> assume next
  // year (e.g. "Jan 5" said in November means next January).
  if (explicitYear == null && date.isBefore(today)) {
    year += 1;
    date = DateTime(year, month, day);
  }
  return date;
}

/// The next date on/after [from] falling on [targetWeekday] (0 = Monday .. 6
/// = Sunday). If [skipToday] is true (an explicit "next X"), a same-day
/// match rolls forward a full week instead of returning today.
DateTime _nextWeekday(DateTime from, int targetWeekday, {required bool skipToday}) {
  final fromWeekday = from.weekday - 1; // DateTime.weekday is 1 = Monday
  var daysAhead = (targetWeekday - fromWeekday + 7) % 7;
  if (daysAhead == 0 && skipToday) daysAhead = 7;
  return from.add(Duration(days: daysAhead));
}

String _weekdayCode(String name) {
  const codes = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return codes[_weekdayNames.indexOf(name.toLowerCase())];
}

class _TimeResult {
  const _TimeResult(this.minuteOfDay, this.remaining);
  final int? minuteOfDay;
  final String remaining;
}

_TimeResult _extractTime(String text) {
  final match = _timePattern.firstMatch(text);
  if (match != null) {
    var hour = int.parse(match.group(1)!);
    final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
    final meridiem = match.group(3)!.toLowerCase();
    if (meridiem == 'pm' && hour != 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return _TimeResult(hour * 60 + minute, _remove(text, match));
  }

  final match24 = _time24Pattern.firstMatch(text);
  if (match24 != null) {
    final hour = int.parse(match24.group(1)!);
    final minute = int.parse(match24.group(2)!);
    return _TimeResult(hour * 60 + minute, _remove(text, match24));
  }

  return _TimeResult(null, text);
}

String _remove(String text, Match match) =>
    text.replaceRange(match.start, match.end, ' ');
