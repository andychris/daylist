import 'package:daylist/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated/schema.dart';
import '../generated/schema_v1.dart' as v1;
import '../generated/schema_v2.dart' as v2;
import '../generated/schema_v3.dart' as v3;
import '../generated/schema_v4.dart' as v4;

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

  test(
    'v2 -> v3 backfills recurrenceRule=daily and migrates category into a matching Project',
    () async {
      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.forTesting,
        createItems: (batch, oldDb) {
          batch.insert(
            oldDb.tasks,
            v2.TasksCompanion.insert(
              title: 'Standup',
              sortOrder: 1000,
              category: const Value('work'),
            ),
          );
        },
        validateItems: (newDb) async {
          final projects = await newDb.select(newDb.projects).get();
          expect(
            projects.map((p) => p.name),
            containsAll(<String>[
              'Personal',
              'Work',
              'Health',
              'Errands',
              'Shopping',
              'Other',
            ]),
          );

          final task = await newDb.select(newDb.tasks).getSingle();
          expect(task.title, 'Standup');
          // Pre-existing rows keep behaving exactly like the daily habits
          // they were under the old model.
          expect(task.recurrenceRule, 'daily');
          expect(task.dueDate, isNull);
          expect(task.priority, 'p4');

          final workProject = projects.singleWhere((p) => p.name == 'Work');
          expect(task.projectId, workProject.id);
        },
      );
    },
  );

  test('v3 -> v4 adds the SavedFilters table', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.tasks,
          v3.TasksCompanion.insert(title: 'Meditate', sortOrder: 1000),
        );
      },
      validateItems: (newDb) async {
        final id = await newDb
            .into(newDb.savedFilters)
            .insert(
              v4.SavedFiltersCompanion.insert(
                name: 'P1 today',
                query: 'p1 & today',
                sortOrder: 0,
              ),
            );
        final filter = await (newDb.select(
          newDb.savedFilters,
        )..where((f) => f.id.equals(id))).getSingle();
        expect(filter.query, 'p1 & today');
      },
    );
  });
}
