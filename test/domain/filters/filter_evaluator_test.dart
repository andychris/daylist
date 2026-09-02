import 'package:daylist/domain/filters/filter_evaluator.dart';
import 'package:daylist/domain/filters/filter_parser.dart';
import 'package:daylist/domain/models/checklist_item.dart';
import 'package:daylist/domain/models/task_category.dart';
import 'package:daylist/domain/models/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 15);
  var nextId = 1;

  ChecklistItem item({
    TaskPriority priority = TaskPriority.p4,
    int? projectId,
    DateTime? dueDate,
    String? recurrenceRule,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: nextId++,
      title: 'Task',
      isDoneToday: false,
      sortOrder: 0,
      category: TaskCategory.other,
      reminderMinuteOfDay: null,
      priority: priority,
      projectId: projectId,
      dueDate: dueDate,
      recurrenceRule: recurrenceRule,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      sectionId: null,
    );
  }

  final baseCtx = FilterEvalContext(
    today: today,
    projectNameById: const {1: 'Work', 2: 'Home'},
    labelIdsByTaskId: const {},
    labelNameById: const {10: 'urgent', 11: 'errand'},
  );

  bool matches(String query, ChecklistItem task, [FilterEvalContext? ctx]) =>
      evaluateFilter(parseFilterQuery(query), task, ctx ?? baseCtx);

  test('p1 matches only p1 tasks', () {
    expect(matches('p1', item(priority: TaskPriority.p1)), isTrue);
    expect(matches('p1', item(priority: TaskPriority.p2)), isFalse);
  });

  test('today matches a task due today or a matching recurring task', () {
    expect(matches('today', item(dueDate: today)), isTrue);
    expect(matches('today', item(recurrenceRule: 'daily')), isTrue);
    expect(matches('today', item(dueDate: DateTime(2026, 3, 20))), isFalse);
  });

  test('overdue matches only a past-due, non-recurring task', () {
    expect(matches('overdue', item(dueDate: DateTime(2026, 3, 10))), isTrue);
    expect(matches('overdue', item(dueDate: today)), isFalse);
    expect(matches('overdue', item(recurrenceRule: 'daily')), isFalse);
  });

  group('7 days', () {
    test('matches overdue, today, and up to 6 days out', () {
      expect(matches('7 days', item(dueDate: DateTime(2026, 3, 10))), isTrue);
      expect(matches('7 days', item(dueDate: today)), isTrue);
      expect(matches('7 days', item(dueDate: DateTime(2026, 3, 21))), isTrue);
    });

    test('does not match 7+ days out', () {
      expect(matches('7 days', item(dueDate: DateTime(2026, 3, 22))), isFalse);
    });

    test('a recurring task matches if its rule hits within the window', () {
      expect(
        matches('7 days', item(recurrenceRule: 'weekly:MON', createdAt: DateTime(2026, 1, 1))),
        isTrue, // Mar 16 (Mon) is within the window
      );
    });

    test('an undated task never matches', () {
      expect(matches('7 days', item()), isFalse);
    });
  });

  test('no date matches only undated, non-recurring tasks', () {
    expect(matches('no date', item()), isTrue);
    expect(matches('no date', item(dueDate: today)), isFalse);
    expect(matches('no date', item(recurrenceRule: 'daily')), isFalse);
  });

  test('#Project matches by project name, case-insensitively', () {
    expect(matches('#work', item(projectId: 1)), isTrue);
    expect(matches('#Work', item(projectId: 2)), isFalse);
    expect(matches('#Work', item()), isFalse);
  });

  test('@Label matches by label name, case-insensitively', () {
    final task = item();
    final ctx = FilterEvalContext(
      today: today,
      projectNameById: const {},
      labelIdsByTaskId: {
        task.id: {10},
      },
      labelNameById: const {10: 'urgent', 11: 'errand'},
    );
    expect(matches('@urgent', task, ctx), isTrue);
    expect(matches('@errand', task, ctx), isFalse);
  });

  test('combined query: p1 & (today | overdue) & !#Work', () {
    const query = 'p1 & (today | overdue) & !#Work';
    expect(
      matches(query, item(priority: TaskPriority.p1, dueDate: today, projectId: 2)),
      isTrue,
    );
    expect(
      matches(
        query,
        item(priority: TaskPriority.p1, dueDate: today, projectId: 1),
      ),
      isFalse, // excluded by !#Work
    );
    expect(
      matches(query, item(priority: TaskPriority.p2, dueDate: today)),
      isFalse, // wrong priority
    );
    expect(
      matches(query, item(priority: TaskPriority.p1, dueDate: DateTime(2026, 3, 20))),
      isFalse, // not today or overdue
    );
  });
}
