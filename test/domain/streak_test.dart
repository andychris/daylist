import 'package:daylist/domain/date_utils.dart';
import 'package:daylist/domain/models/task_lifespan.dart';
import 'package:daylist/domain/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 15);
  // A pre-migration "daily habit" task: recurs every day forever.
  final task = TaskLifespan(
    id: 1,
    createdAt: DateTime(2026, 1, 1),
    archivedAt: null,
    recurrenceRule: 'daily',
    dueDate: null,
  );

  Map<String, int> completedFor(List<DateTime> doneDays) => {
    for (final d in doneDays) formatLocalDate(d): 1,
  };

  test('no completion history at all is a zero streak', () {
    final streak = computeCurrentStreak(
      today: today,
      tasks: [task],
      completedCountsByDate: const {},
    );
    expect(streak, 0);
  });

  test('N consecutive fully-done days (including today) count as N', () {
    final doneDays = List.generate(5, (i) => addDays(today, -i));
    final streak = computeCurrentStreak(
      today: today,
      tasks: [task],
      completedCountsByDate: completedFor(doneDays),
    );
    expect(streak, 5);
  });

  test('a gap breaks the streak', () {
    // Done today and yesterday, but not the day before -> streak of 2.
    final doneDays = [today, addDays(today, -1)];
    final streak = computeCurrentStreak(
      today: today,
      tasks: [task],
      completedCountsByDate: completedFor(doneDays),
    );
    expect(streak, 2);
  });

  test('an incomplete today does not zero out an ongoing streak', () {
    // Yesterday and the day before are fully done; today has nothing logged.
    final doneDays = [addDays(today, -1), addDays(today, -2)];
    final streak = computeCurrentStreak(
      today: today,
      tasks: [task],
      completedCountsByDate: completedFor(doneDays),
    );
    expect(streak, 2);
  });

  test('a day with no active tasks breaks the streak', () {
    // Task didn't exist yet 3 days ago, so that day has zero active tasks.
    final recentTask = TaskLifespan(
      id: 1,
      createdAt: addDays(today, -1),
      archivedAt: null,
      recurrenceRule: 'daily',
      dueDate: null,
    );
    final streak = computeCurrentStreak(
      today: today,
      tasks: [recentTask],
      completedCountsByDate: completedFor([today, addDays(today, -1)]),
    );
    expect(streak, 2);
  });

  test('a one-off task due today counts toward the day, not future days', () {
    final oneOff = TaskLifespan(
      id: 2,
      createdAt: addDays(today, -5),
      archivedAt: null,
      recurrenceRule: null,
      dueDate: today,
    );
    final streak = computeCurrentStreak(
      today: today,
      tasks: [oneOff],
      completedCountsByDate: completedFor([today]),
    );
    expect(streak, 1);
  });

  test('an overdue one-off task keeps counting as active on later days', () {
    final overdue = TaskLifespan(
      id: 3,
      createdAt: addDays(today, -5),
      archivedAt: null,
      recurrenceRule: null,
      dueDate: addDays(today, -3),
    );
    // Not completed on its due date, so days after that (including today)
    // aren't "fully done" -> zero streak, but it must still be counted as
    // active (not silently dropped) for those days to matter.
    final streak = computeCurrentStreak(
      today: today,
      tasks: [overdue],
      completedCountsByDate: const {},
    );
    expect(streak, 0);
  });
}
