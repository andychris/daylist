import '../models/task_priority.dart';

class ParsedQuickAddResult {
  const ParsedQuickAddResult({
    required this.cleanedTitle,
    required this.dueDate,
    required this.dueTimeMinuteOfDay,
    required this.recurrenceRule,
    required this.priority,
    required this.projectName,
    required this.labelNames,
  });

  /// The title with every recognized token (dates, `pN`, `#project`,
  /// `@label`) stripped out and whitespace collapsed.
  final String cleanedTitle;

  /// Null if no date/recurrence was recognized, or the task recurs (a
  /// recurring task's "next due day" is derived from [recurrenceRule], not
  /// stored here — see `domain/due_logic.dart`).
  final DateTime? dueDate;

  /// Minutes since local midnight, if a time was recognized.
  final int? dueTimeMinuteOfDay;

  /// A `matchesRecurrence`-compatible rule string (see
  /// `domain/due_logic.dart`), or null for a one-off task — the default
  /// when nothing in the input asked for recurrence.
  final String? recurrenceRule;

  /// Null if no `p1`-`p4` flag was found — the caller should fall back to
  /// its own default rather than assume one here.
  final TaskPriority? priority;

  /// Raw `#Name` text (without the `#`), or null if none was found. The
  /// caller resolves this against existing projects (case-insensitively)
  /// or offers to create a new one — this parser doesn't know about
  /// projects, only text.
  final String? projectName;

  /// Raw `@Name` text (without the `@`) for every label tag found.
  final List<String> labelNames;
}
