import 'package:daylist/domain/calendar_rings.dart';
import 'package:daylist/domain/models/day_rings.dart';
import 'package:daylist/domain/models/task_lifespan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // March 2026: 31 days, Mar 1 is a Sunday.
  final monthAnchor = DateTime(2026, 3, 15);

  DayRings ringsFor(List<DayRings> rings, DateTime date) =>
      rings.firstWhere((r) => r.date == date);

  test('no tasks all month: no goal anywhere, consistency is null', () {
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: const [],
      completedCountsByDate: const {},
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
      tasks: [TaskLifespan(id: 1, createdAt: createdAt, archivedAt: null)],
      completedCountsByDate: const {},
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
        TaskLifespan(
          id: 1,
          createdAt: DateTime(2026, 3, 1),
          archivedAt: DateTime(2026, 3, 10, 18, 0),
        ),
      ],
      completedCountsByDate: const {},
    );

    expect(ringsFor(rings, DateTime(2026, 3, 10)).hasGoal, isTrue);
    expect(ringsFor(rings, DateTime(2026, 3, 11)).hasGoal, isFalse);
  });

  test('rolling average pulls into the previous month for early-month days', () {
    // One task active the whole time, completed every day in the last week
    // of February, not completed at all in March.
    final tasks = [
      TaskLifespan(id: 1, createdAt: DateTime(2026, 2, 1), archivedAt: null),
    ];
    final completedCountsByDate = {
      for (var d = 23; d <= 28; d++) '2026-02-${d.toString().padLeft(2, '0')}': 1,
    };

    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: tasks,
      completedCountsByDate: completedCountsByDate,
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
      TaskLifespan(id: 1, createdAt: DateTime(2026, 3, 1), archivedAt: null),
      TaskLifespan(id: 2, createdAt: DateTime(2026, 3, 1), archivedAt: null),
    ];
    final rings = computeMonthRings(
      monthAnchor: monthAnchor,
      tasks: tasks,
      completedCountsByDate: const {'2026-03-05': 1},
    );

    final day = ringsFor(rings, DateTime(2026, 3, 5));
    expect(day.totalActive, 2);
    expect(day.completed, 1);
    expect(day.progressFraction, 0.5);
  });
}
