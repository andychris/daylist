import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/repositories/filter_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FilterRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FilterRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('adding filters assigns increasing sortOrder', () async {
    await repository.addFilter(name: 'P1 today', query: 'p1 & today');
    await repository.addFilter(name: 'Overdue', query: 'overdue');

    final filters = await repository.watchFilters().first;
    expect(filters.map((f) => f.name), ['P1 today', 'Overdue']);
    expect(filters[1].sortOrder, greaterThan(filters[0].sortOrder));
  });

  test('updateFilter changes only the given fields', () async {
    final id = await repository.addFilter(name: 'P1 today', query: 'p1 & today');
    await repository.updateFilter(id: id, query: 'p1 & overdue');

    final filter = (await repository.watchFilters().first).single;
    expect(filter.name, 'P1 today');
    expect(filter.query, 'p1 & overdue');
  });

  test('deleteFilter removes it', () async {
    final id = await repository.addFilter(name: 'P1 today', query: 'p1 & today');
    await repository.deleteFilter(id);
    expect(await repository.watchFilters().first, isEmpty);
  });
}
