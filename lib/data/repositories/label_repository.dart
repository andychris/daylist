import 'package:drift/drift.dart';

import '../../domain/models/label.dart';
import '../database/app_database.dart';

class LabelRepository {
  LabelRepository(this._db);

  final AppDatabase _db;

  Label _toDomain(LabelRow row) =>
      Label(id: row.id, name: row.name, colorHex: row.colorHex);

  Stream<List<Label>> watchLabels() {
    final query = _db.select(_db.labels)
      ..orderBy([(l) => OrderingTerm(expression: l.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Stream<List<Label>> watchLabelsForTask(int taskId) {
    final query = _db.select(_db.labels).join([
      innerJoin(
        _db.taskLabels,
        _db.taskLabels.labelId.equalsExp(_db.labels.id) &
            _db.taskLabels.taskId.equals(taskId),
      ),
    ]);
    return query.watch().map(
      (rows) => rows.map((r) => _toDomain(r.readTable(_db.labels))).toList(),
    );
  }

  /// Every task's label ids, all at once — for the filter engine and
  /// label-based task lookups, which need to check membership across many
  /// tasks rather than one at a time.
  Stream<Map<int, Set<int>>> watchAllTaskLabelPairs() {
    return _db.select(_db.taskLabels).watch().map((rows) {
      final byTask = <int, Set<int>>{};
      for (final row in rows) {
        byTask.putIfAbsent(row.taskId, () => {}).add(row.labelId);
      }
      return byTask;
    });
  }

  Future<int> addLabel({required String name, String colorHex = '#808080'}) {
    final trimmed = name.trim();
    return _db
        .into(_db.labels)
        .insert(
          LabelsCompanion.insert(name: trimmed, colorHex: Value(colorHex)),
        );
  }

  Future<void> deleteLabel(int id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.taskLabels,
      )..where((tl) => tl.labelId.equals(id))).go();
      await (_db.delete(_db.labels)..where((l) => l.id.equals(id))).go();
    });
  }

  /// Replaces a task's full label set with [labelIds].
  Future<void> setTaskLabels(int taskId, List<int> labelIds) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.taskLabels,
      )..where((tl) => tl.taskId.equals(taskId))).go();
      for (final labelId in labelIds) {
        await _db
            .into(_db.taskLabels)
            .insert(
              TaskLabelsCompanion.insert(taskId: taskId, labelId: labelId),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
