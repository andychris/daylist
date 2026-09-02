import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/repositories/section_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SectionRepository repository;
  late int projectId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SectionRepository(db);
    projectId = await db
        .into(db.projects)
        .insert(ProjectsCompanion.insert(name: 'Launch', sortOrder: 0));
  });

  tearDown(() async {
    await db.close();
  });

  test('sections are scoped to their project and ordered', () async {
    final otherProjectId = await db
        .into(db.projects)
        .insert(ProjectsCompanion.insert(name: 'Other', sortOrder: 1000));
    await repository.addSection(name: 'To Do', projectId: projectId);
    await repository.addSection(name: 'Done', projectId: projectId);
    await repository.addSection(name: 'Backlog', projectId: otherProjectId);

    final sections = await repository.watchSectionsForProject(projectId).first;
    expect(sections.map((s) => s.name), ['To Do', 'Done']);
  });

  test('renameSection updates the name only', () async {
    final id = await repository.addSection(name: 'To Do', projectId: projectId);
    await repository.renameSection(id: id, name: 'Doing');

    final sections = await repository.watchSectionsForProject(projectId).first;
    expect(sections.single.name, 'Doing');
  });

  test('deleteSection moves its tasks back to no-section', () async {
    final sectionId = await repository.addSection(
      name: 'To Do',
      projectId: projectId,
    );
    final taskId = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Design',
            sortOrder: 0,
            projectId: Value(projectId),
            sectionId: Value(sectionId),
          ),
        );

    await repository.deleteSection(sectionId);

    expect(await repository.watchSectionsForProject(projectId).first, isEmpty);
    final task = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    expect(task.sectionId, isNull);
  });
}
