import 'package:daylist/data/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated/schema.dart';
import '../generated/schema_v1.dart' as v1;
import '../generated/schema_v2.dart' as v2;

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test('all schema versions have a valid migration path', () async {
    for (var version = 1; version < GeneratedHelper.versions.last; version++) {
      final connection = await verifier.startAt(version);
      final db = AppDatabase.forTesting(connection.executor);
      await verifier.migrateAndValidate(db, version + 1);
      await db.close();
    }
  });

  test('v1 -> v2 adds category (defaulted) and reminderMinuteOfDay columns', () async {
    // Schema-level check: the raw column exists post-migration with the
    // SQL-level default applied. Data flows through the generated v1/v2
    // schema classes here, which are plain column definitions with no
    // TaskCategoryConverter attached — that's why this reads the raw
    // string, not the enum (see the next test for the converted read).
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.tasks,
          v1.TasksCompanion.insert(title: 'Meditate', sortOrder: 1000),
        );
      },
      validateItems: (newDb) async {
        final task = await newDb.select(newDb.tasks).getSingle();
        expect(task.title, 'Meditate');
        expect(task.category, 'other');
        expect(task.reminderMinuteOfDay, null);
      },
    );
  });

}
