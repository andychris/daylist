import 'package:drift/drift.dart';

import '../../domain/models/saved_filter.dart';
import '../database/app_database.dart';

class FilterRepository {
  FilterRepository(this._db);

  final AppDatabase _db;

  SavedFilter _toDomain(SavedFilterRow row) => SavedFilter(
    id: row.id,
    name: row.name,
    query: row.query,
    colorHex: row.colorHex,
    sortOrder: row.sortOrder,
  );

  Stream<List<SavedFilter>> watchFilters() {
    final query = _db.select(_db.savedFilters)
      ..orderBy([(f) => OrderingTerm(expression: f.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<int> addFilter({
    required String name,
    required String query,
    String colorHex = '#5B4EE8',
  }) async {
    final maxOrder = await (_db.selectOnly(_db.savedFilters)
          ..addColumns([_db.savedFilters.sortOrder.max()]))
        .map((row) => row.read(_db.savedFilters.sortOrder.max()))
        .getSingleOrNull();

    return _db
        .into(_db.savedFilters)
        .insert(
          SavedFiltersCompanion.insert(
            name: name.trim(),
            query: query.trim(),
            colorHex: Value(colorHex),
            sortOrder: (maxOrder ?? 0) + 1000,
          ),
        );
  }

  Future<void> updateFilter({
    required int id,
    String? name,
    String? query,
    String? colorHex,
  }) {
    return (_db.update(_db.savedFilters)..where((f) => f.id.equals(id))).write(
      SavedFiltersCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        query: query != null ? Value(query.trim()) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteFilter(int id) {
    return (_db.delete(_db.savedFilters)..where((f) => f.id.equals(id))).go();
  }
}
