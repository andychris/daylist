import 'package:drift/drift.dart';

import '../../../domain/models/project_view_type.dart';

class ProjectViewTypeConverter extends TypeConverter<ProjectViewType, String> {
  const ProjectViewTypeConverter();

  @override
  ProjectViewType fromSql(String fromDb) =>
      ProjectViewType.values.asNameMap()[fromDb] ?? ProjectViewType.list;

  @override
  String toSql(ProjectViewType value) => value.name;
}
