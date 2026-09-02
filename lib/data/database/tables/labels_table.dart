import 'package:drift/drift.dart';

@DataClassName('LabelRow')
class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get colorHex => text().withDefault(const Constant('#808080'))();
}
