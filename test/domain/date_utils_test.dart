import 'package:daylist/domain/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatLocalDate / parseLocalDate', () {
    test('round-trips a date', () {
      final date = DateTime(2026, 3, 5);
      final key = formatLocalDate(date);
      expect(key, '2026-03-05');
      expect(parseLocalDate(key), date);
    });

    test('pads single-digit month and day', () {
      expect(formatLocalDate(DateTime(2026, 1, 2)), '2026-01-02');
    });
  });

  group('isTaskActiveOn', () {
    final createdAt = DateTime(2026, 3, 5, 14, 30);

    test('was not active before it was created', () {
      expect(isTaskActiveOn(createdAt, null, DateTime(2026, 3, 4)), isFalse);
    });

    test('active on and after creation day when never archived', () {
      expect(isTaskActiveOn(createdAt, null, DateTime(2026, 3, 5)), isTrue);
      expect(isTaskActiveOn(createdAt, null, DateTime(2026, 3, 20)), isTrue);
    });

    test('still active on the day it was archived', () {
      final archivedAt = DateTime(2026, 3, 10, 9, 0);
      expect(isTaskActiveOn(createdAt, archivedAt, DateTime(2026, 3, 10)), isTrue);
    });

    test('not active the day before archival is impossible; active up to archival day', () {
      final archivedAt = DateTime(2026, 3, 10, 9, 0);
      expect(isTaskActiveOn(createdAt, archivedAt, DateTime(2026, 3, 9)), isTrue);
    });

    test('not active the day after archival', () {
      final archivedAt = DateTime(2026, 3, 10, 9, 0);
      expect(isTaskActiveOn(createdAt, archivedAt, DateTime(2026, 3, 11)), isFalse);
    });
  });

  group('addDays', () {
    test('adds days within a month', () {
      expect(addDays(DateTime(2026, 3, 5), 3), DateTime(2026, 3, 8));
    });

    test('rolls over a month boundary', () {
      expect(addDays(DateTime(2026, 3, 1), -6), DateTime(2026, 2, 23));
    });

    test('rolls over a year boundary', () {
      expect(addDays(DateTime(2026, 1, 1), -1), DateTime(2025, 12, 31));
    });
  });
}
