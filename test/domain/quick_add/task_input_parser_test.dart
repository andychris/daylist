import 'package:daylist/domain/models/task_priority.dart';
import 'package:daylist/domain/quick_add/task_input_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Wednesday.
  final now = DateTime(2026, 3, 4, 9, 30);

  group('plain title, nothing to parse', () {
    test('leaves the title untouched', () {
      final result = parseQuickAddInput('Buy milk', now: now);
      expect(result.cleanedTitle, 'Buy milk');
      expect(result.dueDate, isNull);
      expect(result.dueTimeMinuteOfDay, isNull);
      expect(result.recurrenceRule, isNull);
      expect(result.priority, isNull);
      expect(result.projectName, isNull);
      expect(result.labelNames, isEmpty);
    });
  });

  group('relative dates', () {
    test('today', () {
      final result = parseQuickAddInput('Call mom today', now: now);
      expect(result.cleanedTitle, 'Call mom');
      expect(result.dueDate, DateTime(2026, 3, 4));
    });

    test('tomorrow', () {
      final result = parseQuickAddInput('Call mom tomorrow', now: now);
      expect(result.dueDate, DateTime(2026, 3, 5));
    });

    test('yesterday', () {
      final result = parseQuickAddInput('Call mom yesterday', now: now);
      expect(result.dueDate, DateTime(2026, 3, 3));
    });

    test('in N days', () {
      final result = parseQuickAddInput('Call mom in 5 days', now: now);
      expect(result.dueDate, DateTime(2026, 3, 9));
      expect(result.cleanedTitle, 'Call mom');
    });

    test('a bare weekday means the closest upcoming one', () {
      // "now" is Wednesday Mar 4 -> next Friday is Mar 6.
      final result = parseQuickAddInput('Call mom friday', now: now);
      expect(result.dueDate, DateTime(2026, 3, 6));
    });

    test('a bare weekday equal to today means today', () {
      final result = parseQuickAddInput('Call mom wednesday', now: now);
      expect(result.dueDate, DateTime(2026, 3, 4));
    });

    test('"this X" behaves like the bare weekday', () {
      final result = parseQuickAddInput('Call mom this friday', now: now);
      expect(result.dueDate, DateTime(2026, 3, 6));
    });

    test('"next X" on the same weekday skips a full week', () {
      final result = parseQuickAddInput('Call mom next wednesday', now: now);
      expect(result.dueDate, DateTime(2026, 3, 11));
    });
  });

  group('specific dates', () {
    test('month + day rolls to next year when already past this year', () {
      // "now" is March 2026, so "Jan 5" must mean Jan 2027.
      final result = parseQuickAddInput('Renew passport Jan 5', now: now);
      expect(result.dueDate, DateTime(2027, 1, 5));
    });

    test('month + day this year when still ahead', () {
      final result = parseQuickAddInput('Renew passport Oct 15', now: now);
      expect(result.dueDate, DateTime(2026, 10, 15));
    });

    test('full month name with ordinal day and explicit year', () {
      final result = parseQuickAddInput(
        'Renew passport May 3rd 2027',
        now: now,
      );
      expect(result.dueDate, DateTime(2027, 5, 3));
      expect(result.cleanedTitle, 'Renew passport');
    });

    test('ISO date', () {
      final result = parseQuickAddInput('Renew passport 2026-11-20', now: now);
      expect(result.dueDate, DateTime(2026, 11, 20));
    });
  });

  group('times', () {
    test('a time with no date defaults the due date to today', () {
      final result = parseQuickAddInput('Standup at 10:30am', now: now);
      expect(result.dueDate, DateTime(2026, 3, 4));
      expect(result.dueTimeMinuteOfDay, 10 * 60 + 30);
      expect(result.cleanedTitle, 'Standup');
    });

    test('pm rolls the hour into 24h', () {
      final result = parseQuickAddInput('Meet Sam Oct 15 at 4pm', now: now);
      expect(result.dueDate, DateTime(2026, 10, 15));
      expect(result.dueTimeMinuteOfDay, 16 * 60);
    });

    test('12am is midnight, 12pm is noon', () {
      expect(
        parseQuickAddInput('Task at 12am', now: now).dueTimeMinuteOfDay,
        0,
      );
      expect(
        parseQuickAddInput('Task at 12pm', now: now).dueTimeMinuteOfDay,
        12 * 60,
      );
    });

    test('24-hour time', () {
      final result = parseQuickAddInput('Standup 16:30', now: now);
      expect(result.dueTimeMinuteOfDay, 16 * 60 + 30);
    });
  });

  group('recurrence', () {
    test('every day', () {
      final result = parseQuickAddInput('Meditate every day', now: now);
      expect(result.recurrenceRule, 'daily');
      expect(result.dueDate, isNull);
      expect(result.cleanedTitle, 'Meditate');
    });

    test('every weekday', () {
      final result = parseQuickAddInput('Standup every weekday', now: now);
      expect(result.recurrenceRule, 'weekdays');
    });

    test('every <weekday name>', () {
      final result = parseQuickAddInput('Team sync every monday', now: now);
      expect(result.recurrenceRule, 'weekly:MON');
    });

    test('every N days', () {
      final result = parseQuickAddInput('Water plants every 3 days', now: now);
      expect(result.recurrenceRule, 'every:3');
    });

    test('every month on the Nth', () {
      final result = parseQuickAddInput(
        'Pay rent every month on the 1st',
        now: now,
      );
      expect(result.recurrenceRule, 'monthly:1');
    });

    test('recurrence takes priority over an incidental date-shaped phrase', () {
      // A recurring task has no fixed one-time due date.
      final result = parseQuickAddInput('Meditate every day', now: now);
      expect(result.dueDate, isNull);
    });
  });

  group('priority', () {
    test('p1 through p4, case-insensitive', () {
      expect(
        parseQuickAddInput('Fix bug p1', now: now).priority,
        TaskPriority.p1,
      );
      expect(
        parseQuickAddInput('Fix bug P2', now: now).priority,
        TaskPriority.p2,
      );
      expect(
        parseQuickAddInput('Fix bug p4', now: now).priority,
        TaskPriority.p4,
      );
    });

    test('does not match p-followed-by-word-chars (e.g. "p10", "prep")', () {
      expect(parseQuickAddInput('prep for meeting', now: now).priority, isNull);
      expect(parseQuickAddInput('order p100 parts', now: now).priority, isNull);
    });

    test('strips the flag from the title', () {
      final result = parseQuickAddInput('Fix bug p1', now: now);
      expect(result.cleanedTitle, 'Fix bug');
    });
  });

  group('project and label tags', () {
    test('#Project is extracted and stripped', () {
      final result = parseQuickAddInput('Plan launch #Work', now: now);
      expect(result.projectName, 'Work');
      expect(result.cleanedTitle, 'Plan launch');
    });

    test('multiple @Label tags are all collected', () {
      final result = parseQuickAddInput(
        'Plan launch @urgent @client',
        now: now,
      );
      expect(result.labelNames, ['urgent', 'client']);
      expect(result.cleanedTitle, 'Plan launch');
    });

    test('only the first #Project tag counts; extras are just stripped', () {
      final result = parseQuickAddInput(
        'Plan launch #Work #Extra',
        now: now,
      );
      expect(result.projectName, 'Work');
    });
  });

  group('findHighlightRanges', () {
    test('covers every recognized token', () {
      const text = 'Ship release p1 #Work @urgent tomorrow at 5pm';
      final ranges = findHighlightRanges(text);
      final substrings = ranges.map((r) => text.substring(r.start, r.end)).toSet();
      expect(substrings, containsAll(<String>['p1', '#Work', '@urgent', 'tomorrow']));
    });

    test('an unrecognized plain title has no ranges', () {
      expect(findHighlightRanges('Buy milk'), isEmpty);
    });
  });

  group('combined tokens', () {
    test('everything together, in any order', () {
      final result = parseQuickAddInput(
        'Ship release p1 #Work @urgent tomorrow at 5pm',
        now: now,
      );
      expect(result.cleanedTitle, 'Ship release');
      expect(result.priority, TaskPriority.p1);
      expect(result.projectName, 'Work');
      expect(result.labelNames, ['urgent']);
      expect(result.dueDate, DateTime(2026, 3, 5));
      expect(result.dueTimeMinuteOfDay, 17 * 60);
    });
  });
}
