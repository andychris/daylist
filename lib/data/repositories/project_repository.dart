import 'package:drift/drift.dart';

import '../../domain/models/project.dart';
import '../../domain/models/project_view_type.dart';
import '../database/app_database.dart';

class ProjectRepository {
  ProjectRepository(this._db);

  final AppDatabase _db;

  Project _toDomain(ProjectRow row) => Project(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    isFavorite: row.isFavorite,
    parentProjectId: row.parentProjectId,
    sortOrder: row.sortOrder,
    viewType: row.viewType,
  );

  Stream<List<Project>> watchProjects() {
    final query = _db.select(_db.projects)
      ..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<int> addProject({
    required String name,
    String colorHex = '#5B4EE8',
    int? parentProjectId,
  }) async {
    final trimmed = name.trim();
    return _db.transaction(() async {
      final maxOrder = await (_db.selectOnly(_db.projects)
            ..addColumns([_db.projects.sortOrder.max()]))
          .map((row) => row.read(_db.projects.sortOrder.max()))
          .getSingleOrNull();

      return _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              name: trimmed,
              sortOrder: (maxOrder ?? 0) + 1000,
              colorHex: Value(colorHex),
              parentProjectId: Value(parentProjectId),
            ),
          );
    });
  }

  /// Updates an existing project. Omitted parameters leave that field
  /// unchanged; pass [parentProjectId] as `Value(null)` to explicitly move a
  /// project to top-level (vs. `Value.absent()`, the default, to leave it
  /// as-is).
  Future<void> updateProject({
    required int id,
    String? name,
    String? colorHex,
    bool? isFavorite,
    Value<int?> parentProjectId = const Value.absent(),
    ProjectViewType? viewType,
  }) {
    return (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
      ProjectsCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        isFavorite: isFavorite != null
            ? Value(isFavorite)
            : const Value.absent(),
        parentProjectId: parentProjectId,
        viewType: viewType != null ? Value(viewType) : const Value.absent(),
      ),
    );
  }

  /// Deletes a project, moving any of its tasks and child projects to
  /// Inbox/top-level rather than orphaning or cascading the delete.
  Future<void> deleteProject(int id) {
    return _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.projectId.equals(id)))
          .write(const TasksCompanion(projectId: Value(null)));
      await (_db.update(
        _db.projects,
      )..where((p) => p.parentProjectId.equals(id))).write(
        const ProjectsCompanion(parentProjectId: Value(null)),
      );
      await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
    });
  }
}
