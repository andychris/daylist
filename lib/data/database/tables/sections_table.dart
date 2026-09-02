import 'package:drift/drift.dart';

import 'projects_table.dart';

@DataClassName('SectionRow')
class Sections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get projectId => integer().references(Projects, #id)();
  RealColumn get sortOrder => real()();
}
