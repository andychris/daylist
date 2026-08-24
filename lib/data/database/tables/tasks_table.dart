import 'package:drift/drift.dart';

import '../converters/task_category_converter.dart';

@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  RealColumn get sortOrder => real()();
  TextColumn get category => text()
      .map(const TaskCategoryConverter())
      .withDefault(const Constant('other'))();
  IntColumn get reminderMinuteOfDay => integer().nullable()();
}
