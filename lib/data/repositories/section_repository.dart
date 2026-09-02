import 'package:drift/drift.dart';

import '../../domain/models/section.dart';
import '../database/app_database.dart';

class SectionRepository {
  SectionRepository(this._db);

  final AppDatabase _db;

  Section _toDomain(SectionRow row) => Section(
    id: row.id,
    name: row.name,
    projectId: row.projectId,
    sortOrder: row.sortOrder,
  );

  Stream<List<Section>> watchSectionsForProject(int projectId) {
    final query = _db.select(_db.sections)
      ..where((s) => s.projectId.equals(projectId))
      ..orderBy([(s) => OrderingTerm(expression: s.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<int> addSection({required String name, required int projectId}) async {
    final trimmed = name.trim();
    final maxOrder = await (_db.selectOnly(_db.sections)
          ..addColumns([_db.sections.sortOrder.max()])
          ..where(_db.sections.projectId.equals(projectId)))
        .map((row) => row.read(_db.sections.sortOrder.max()))
        .getSingleOrNull();

    return _db
        .into(_db.sections)
        .insert(
          SectionsCompanion.insert(
            name: trimmed,
            projectId: projectId,
            sortOrder: (maxOrder ?? 0) + 1000,
          ),
        );
  }

  Future<void> renameSection({required int id, required String name}) {
    return (_db.update(_db.sections)..where((s) => s.id.equals(id))).write(
      SectionsCompanion(name: Value(name.trim())),
    );
  }

  /// Deletes a section, moving any of its tasks back to no-section rather
  /// than orphaning them.
  Future<void> deleteSection(int id) {
    return _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.sectionId.equals(id)))
          .write(const TasksCompanion(sectionId: Value(null)));
      await (_db.delete(_db.sections)..where((s) => s.id.equals(id))).go();
    });
  }
}
