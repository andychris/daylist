import 'package:drift/drift.dart';

@DataClassName('SavedFilterRow')
class SavedFilters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get query => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#5B4EE8'))();
  RealColumn get sortOrder => real()();
}
