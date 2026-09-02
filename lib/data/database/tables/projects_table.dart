import 'package:drift/drift.dart';

import '../converters/project_view_type_converter.dart';

@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get colorHex => text().withDefault(const Constant('#5B4EE8'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Null for a top-level project.
  IntColumn get parentProjectId =>
      integer().nullable().references(Projects, #id)();

  RealColumn get sortOrder => real()();
  TextColumn get viewType => text()
      .map(const ProjectViewTypeConverter())
      .withDefault(const Constant('list'))();
}
