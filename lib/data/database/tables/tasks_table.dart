import 'package:drift/drift.dart';

import '../converters/task_category_converter.dart';
import '../converters/task_priority_converter.dart';
import 'projects_table.dart';
import 'sections_table.dart';

@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  RealColumn get sortOrder => real()();

  /// Superseded by [projectId]; kept only so pre-migration rows can be
  /// read during the v3 migration's backfill. Not written to by any code
  /// after that migration.
  TextColumn get category => text()
      .map(const TaskCategoryConverter())
      .withDefault(const Constant('other'))();
  IntColumn get reminderMinuteOfDay => integer().nullable()();

  /// A specific calendar day this (one-off) task is due, or the day it
  /// first became due if [recurrenceRule] is set. Null for an undated
  /// Inbox item.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Non-null means this task recurs — see `matchesRecurrence` in
  /// `domain/due_logic.dart` for the supported rule strings (e.g. `daily`,
  /// `weekdays`, `weekly:MON`, `monthly:15`, `every:3`). Null means a
  /// one-off task, which is the default: nothing here sets this
  /// automatically: a task only recurs if the user explicitly asks for it.
  TextColumn get recurrenceRule => text().nullable()();

  TextColumn get priority => text()
      .map(const TaskPriorityConverter())
      .withDefault(const Constant('p4'))();

  /// Null means the task lives in Inbox (no project).
  IntColumn get projectId =>
      integer().nullable().references(Projects, #id)();

  /// Null means the task isn't in a section (e.g. Inbox, or a project with
  /// no board view).
  IntColumn get sectionId =>
      integer().nullable().references(Sections, #id)();
}
