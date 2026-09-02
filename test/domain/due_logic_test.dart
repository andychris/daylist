import 'package:daylist/domain/due_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesRecurrence', () {
    final anchor = DateTime(2026, 3, 1); // A Sunday.

    test('daily matches every day', () {
      expect(matchesRecurrence('daily', DateTime(2026, 3, 4), anchor), isTrue);
      expect(matchesRecurrence('daily', DateTime(2026, 4, 20), anchor), isTrue);
    });

    test('weekdays excludes Saturday and Sunday', () {
      expect(matchesRecurrence('weekdays', DateTime(2026, 3, 2), anchor), isTrue); // Mon
      expect(matchesRecurrence('weekdays', DateTime(2026, 3, 7), anchor), isFalse); // Sat
      expect(matchesRecurrence('weekdays', DateTime(2026, 3, 1), anchor), isFalse); // Sun
    });

    test('weekly:CODE matches only that weekday', () {
      expect(matchesRecurrence('weekly:MON', DateTime(2026, 3, 2), anchor), isTrue);
      expect(matchesRecurrence('weekly:MON', DateTime(2026, 3, 3), anchor), isFalse);
      expect(matchesRecurrence('weekly:MON', DateTime(2026, 3, 9), anchor), isTrue);
    });

    test('monthly:D matches only that day-of-month', () {
      expect(matchesRecurrence('monthly:15', DateTime(2026, 3, 15), anchor), isTrue);
      expect(matchesRecurrence('monthly:15', DateTime(2026, 4, 15), anchor), isTrue);
      expect(matchesRecurrence('monthly:15', DateTime(2026, 3, 16), anchor), isFalse);
    });

    test('every:N matches every N days starting from the anchor', () {
      expect(matchesRecurrence('every:3', anchor, anchor), isTrue);
      expect(matchesRecurrence('every:3', DateTime(2026, 3, 4), anchor), isTrue);
      expect(matchesRecurrence('every:3', DateTime(2026, 3, 3), anchor), isFalse);
    });

    test('every:N never matches before the anchor', () {
      expect(matchesRecurrence('every:3', DateTime(2026, 2, 27), anchor), isFalse);
    });

    test('an unrecognized rule never matches', () {
      expect(matchesRecurrence('nonsense', anchor, anchor), isFalse);
    });
  });

  group('isTaskDueOn', () {
    final createdAt = DateTime(2026, 3, 1);

    test('a recurring task ignores dueDate and follows the rule', () {
      expect(
        isTaskDueOn(
          createdAt: createdAt,
          archivedAt: null,
          recurrenceRule: 'daily',
          dueDate: null,
          day: DateTime(2026, 5, 1),
        ),
        isTrue,
      );
    });

    test('a one-off task with no dueDate is never due', () {
      expect(
        isTaskDueOn(
          createdAt: createdAt,
          archivedAt: null,
          recurrenceRule: null,
          dueDate: null,
          day: DateTime(2026, 3, 5),
        ),
        isFalse,
      );
    });

    test('a one-off task is not due before its dueDate', () {
      expect(
        isTaskDueOn(
          createdAt: createdAt,
          archivedAt: null,
          recurrenceRule: null,
          dueDate: DateTime(2026, 3, 10),
          day: DateTime(2026, 3, 9),
        ),
        isFalse,
      );
    });

    test('a one-off task is due on its dueDate and stays due after (overdue rolls forward)', () {
      final dueDate = DateTime(2026, 3, 10);
      expect(
        isTaskDueOn(
          createdAt: createdAt,
          archivedAt: null,
          recurrenceRule: null,
          dueDate: dueDate,
          day: dueDate,
        ),
        isTrue,
      );
      expect(
        isTaskDueOn(
          createdAt: createdAt,
          archivedAt: null,
          recurrenceRule: null,
          dueDate: dueDate,
          day: DateTime(2026, 3, 30),
        ),
        isTrue,
      );
    });

    test('archived tasks are never due, even a matching recurring rule', () {
      expect(
        isTaskDueOn(
          createdAt: createdAt,
          archivedAt: DateTime(2026, 3, 5),
          recurrenceRule: 'daily',
          dueDate: null,
          day: DateTime(2026, 3, 6),
        ),
        isFalse,
      );
    });
  });
}
