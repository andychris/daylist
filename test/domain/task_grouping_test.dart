import 'package:daylist/domain/models/checklist_item.dart';
import 'package:daylist/domain/models/task_category.dart';
import 'package:daylist/domain/models/task_priority.dart';
import 'package:daylist/domain/task_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 15);
  var nextId = 1;

  ChecklistItem item({
    DateTime? dueDate,
    String? recurrenceRule,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: nextId++,
      title: 'Task $nextId',
      isDoneToday: false,
      sortOrder: nextId.toDouble(),
      category: TaskCategory.other,
      reminderMinuteOfDay: null,
      priority: TaskPriority.p4,
      projectId: null,
      dueDate: dueDate,
      recurrenceRule: recurrenceRule,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );
  }

  test('a recurring task matching today lands in dueToday', () {
    final grouped = groupTasksByDueness([
      item(recurrenceRule: 'daily'),
    ], today);
    expect(grouped.dueToday, hasLength(1));
    expect(grouped.overdue, isEmpty);
    expect(grouped.upcoming, isEmpty);
    expect(grouped.inbox, isEmpty);
  });

  test("a recurring task not matching today doesn't appear anywhere", () {
    // March 15 2026 is a Sunday; weekly:MON never matches it.
    final grouped = groupTasksByDueness([
      item(recurrenceRule: 'weekly:MON'),
    ], today);
    expect(grouped.dueToday, isEmpty);
    expect(grouped.overdue, isEmpty);
    expect(grouped.upcoming, isEmpty);
    expect(grouped.inbox, isEmpty);
  });

  test('a one-off task due exactly today lands in dueToday', () {
    final grouped = groupTasksByDueness([item(dueDate: today)], today);
    expect(grouped.dueToday, hasLength(1));
  });

  test('a one-off task due before today is overdue', () {
    final grouped = groupTasksByDueness([
      item(dueDate: DateTime(2026, 3, 10)),
    ], today);
    expect(grouped.overdue, hasLength(1));
    expect(grouped.dueToday, isEmpty);
  });

  test('a one-off task due after today is upcoming, keyed by its date', () {
    final futureDate = DateTime(2026, 3, 20);
    final grouped = groupTasksByDueness([
      item(dueDate: futureDate),
    ], today);
    expect(grouped.overdue, isEmpty);
    expect(grouped.dueToday, isEmpty);
    expect(grouped.upcoming.keys, [futureDate]);
    expect(grouped.upcoming[futureDate], hasLength(1));
  });

  test('upcoming dates come back sorted ascending', () {
    final later = DateTime(2026, 3, 25);
    final sooner = DateTime(2026, 3, 18);
    final grouped = groupTasksByDueness([
      item(dueDate: later),
      item(dueDate: sooner),
    ], today);
    expect(grouped.upcoming.keys.toList(), [sooner, later]);
  });

  test('a task with no due date and no recurrence is Inbox', () {
    final grouped = groupTasksByDueness([item()], today);
    expect(grouped.inbox, hasLength(1));
    expect(grouped.overdue, isEmpty);
    expect(grouped.dueToday, isEmpty);
    expect(grouped.upcoming, isEmpty);
  });

  test('every:N recurrence anchored on createdAt', () {
    // Created Mar 13, every 2 days -> due Mar 13, 15, 17... so Mar 15 (today)
    // matches.
    final grouped = groupTasksByDueness([
      item(recurrenceRule: 'every:2', createdAt: DateTime(2026, 3, 13)),
    ], today);
    expect(grouped.dueToday, hasLength(1));
  });

  test('buckets are sorted by sortOrder', () {
    final a = item(dueDate: today);
    final b = item(dueDate: today);
    final grouped = groupTasksByDueness([b, a], today);
    expect(grouped.dueToday.map((t) => t.id), [a.id, b.id]);
  });
}
