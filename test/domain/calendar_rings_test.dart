import 'package:daylist/domain/calendar_rings.dart';
import 'package:daylist/domain/models/day_rings.dart';
import 'package:daylist/domain/models/task_lifespan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // March 2026: 31 days, Mar 1 is a Sunday.
  final monthAnchor = DateTime(2026, 3, 15);
  // The month's last day, so none of these tests' assertions are affected
  // by the future-day short-circuit (that gets its own dedicated tests).
  final monthEnd = DateTime(2026, 3, 31);

  DayRings ringsFor(List<DayRings> rings, DateTime date) =>
      rings.firstWhere((r) => r.date == date);

  // All tasks below are pre-migration-style "daily habits" (recurs every
  // day forever) unless a test is specifically about one-off due dates.
  TaskLifespan dailyTask({
    required int id,
    required DateTime createdAt,
    DateTime? archivedAt,
  }) => TaskLifespan(
    id: id,
    createdAt: createdAt,
    archivedAt: archivedAt,
    recurrenceRule: 'daily',
    dueDate: null,
  );

  test('no tasks all month: no goal anywhere, consistency is null', () {
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: const [],
      completedCountsByDate: const {},
      today: monthEnd,
    );

    expect(rings, hasLength(31));
    for (final day in rings) {
      expect(day.hasGoal, isFalse);
      expect(day.totalActive, 0);
      expect(day.progressFraction, 0.0);
      expect(day.consistencyFraction, isNull);
    }
  });

  test('task created mid-month: days before are excluded from active count '
      'and from the consistency average (not counted as 0)', () {
    final createdAt = DateTime(2026, 3, 10);
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: [dailyTask(id: 1, createdAt: createdAt)],
      completedCountsByDate: const {},
      today: monthEnd,
    );

    final beforeCreation = ringsFor(rings, DateTime(2026, 3, 5));
    expect(beforeCreation.hasGoal, isFalse);
    expect(beforeCreation.totalActive, 0);

    final onCreation = ringsFor(rings, DateTime(2026, 3, 10));
    expect(onCreation.hasGoal, isTrue);
    expect(onCreation.totalActive, 1);
    // No completions logged, but the task existed -> a real (0.0) fraction,
    // not "no data".
    expect(onCreation.consistencyFraction, 0.0);
  });

  test('task archived mid-month: day of archival counts, day after does not', () {
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: [
        dailyTask(
          id: 1,
          createdAt: DateTime(2026, 3, 1),
          archivedAt: DateTime(2026, 3, 10, 18, 0),
        ),
      ],
      completedCountsByDate: const {},
      today: monthEnd,
    );

    expect(ringsFor(rings, DateTime(2026, 3, 10)).hasGoal, isTrue);
    expect(ringsFor(rings, DateTime(2026, 3, 11)).hasGoal, isFalse);
  });

  test('rolling average pulls into the previous month for early-month days', () {
    // One task active the whole time, completed every day in the last week
    // of February, not completed at all in March.
    final tasks = [dailyTask(id: 1, createdAt: DateTime(2026, 2, 1))];
    final completedCountsByDate = {
      for (var d = 23; d <= 28; d++) '2026-02-${d.toString().padLeft(2, '0')}': 1,
    };

    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: tasks,
      completedCountsByDate: completedCountsByDate,
      today: monthEnd,
    );

    // March 1's trailing 7-day window is Feb 23 - Mar 1: six completed days
    // (Feb 23-28) + one uncompleted day (Mar 1) -> 6/7.
    final march1 = ringsFor(rings, DateTime(2026, 3, 1));
    expect(march1.consistencyFraction, closeTo(6 / 7, 1e-9));

    // March 3's window is Feb 25 - Mar 3: four completed (Feb 25-28) + three
    // uncompleted (Mar 1-3) -> 4/7.
    final march3 = ringsFor(rings, DateTime(2026, 3, 3));
    expect(march3.consistencyFraction, closeTo(4 / 7, 1e-9));
  });

  test('multiple tasks with partial completion', () {
    final tasks = [
      dailyTask(id: 1, createdAt: DateTime(2026, 3, 1)),
      dailyTask(id: 2, createdAt: DateTime(2026, 3, 1)),
    ];
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: tasks,
      completedCountsByDate: const {'2026-03-05': 1},
      today: monthEnd,
    );

    final day = ringsFor(rings, DateTime(2026, 3, 5));
    expect(day.totalActive, 2);
    expect(day.completed, 1);
    expect(day.progressFraction, 0.5);
  });

  test('a one-off task only shows a goal on and after its due date', () {
    final tasks = [
      TaskLifespan(
        id: 1,
        createdAt: DateTime(2026, 3, 1),
        archivedAt: null,
        recurrenceRule: null,
        dueDate: DateTime(2026, 3, 12),
      ),
    ];
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: tasks,
      completedCountsByDate: const {},
      today: monthEnd,
    );

    expect(ringsFor(rings, DateTime(2026, 3, 11)).hasGoal, isFalse);
    expect(ringsFor(rings, DateTime(2026, 3, 12)).hasGoal, isTrue);
    // Overdue and not completed -> stays a goal on later days too.
    expect(ringsFor(rings, DateTime(2026, 3, 20)).hasGoal, isTrue);
  });

  group('future days', () {
    // "Today" is mid-month; days after it haven't happened yet.
    final today = DateTime(2026, 3, 15);

    test('a still-active task does not make a future day show a goal', () {
      final rings = computeMonthRings(
        monthAnchor: monthAnchor,
        tasks: [dailyTask(id: 1, createdAt: DateTime(2026, 3, 1))],
        completedCountsByDate: const {},
        today: today,
      );

      final future = ringsFor(rings, DateTime(2026, 3, 20));
      expect(future.hasGoal, isFalse);
      expect(future.totalActive, 0);
      expect(future.completed, 0);
      expect(future.progressFraction, 0.0);
      expect(future.consistencyFraction, isNull);
    });

    test('today itself is computed normally, not treated as future', () {
      final rings = computeMonthRings(
        monthAnchor: monthAnchor,
        tasks: [dailyTask(id: 1, createdAt: DateTime(2026, 3, 1))],
        completedCountsByDate: const {'2026-03-15': 1},
        today: today,
      );

      final todayRings = ringsFor(rings, today);
      expect(todayRings.hasGoal, isTrue);
      expect(todayRings.totalActive, 1);
      expect(todayRings.completed, 1);
      expect(todayRings.progressFraction, 1.0);
    });

    test('a stray completion row for a future date is ignored', () {
      final rings = computeMonthRings(
        monthAnchor: monthAnchor,
        tasks: [dailyTask(id: 1, createdAt: DateTime(2026, 3, 1))],
        completedCountsByDate: const {'2026-03-20': 1},
        today: today,
      );

      final future = ringsFor(rings, DateTime(2026, 3, 20));
      expect(future.hasGoal, isFalse);
      expect(future.completed, 0);
      expect(future.progressFraction, 0.0);
    });
  });
}
