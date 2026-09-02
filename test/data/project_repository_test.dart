import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/repositories/project_repository.dart';
import 'package:daylist/domain/models/project_node.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ProjectRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('adding projects assigns increasing sortOrder', () async {
    await repository.addProject(name: 'Work');
    await repository.addProject(name: 'Home');

    final projects = await repository.watchProjects().first;
    expect(projects.map((p) => p.name), ['Work', 'Home']);
    expect(projects[1].sortOrder, greaterThan(projects[0].sortOrder));
  });

  test('updateProject changes only the given fields', () async {
    final id = await repository.addProject(name: 'Work');

    await repository.updateProject(id: id, isFavorite: true);

    final project = (await repository.watchProjects().first).single;
    expect(project.name, 'Work');
    expect(project.isFavorite, isTrue);
  });

  test('updateProject leaves parentProjectId untouched when omitted, but '
      'can explicitly clear it with Value(null)', () async {
    final parentId = await repository.addProject(name: 'Work');
    final childId = await repository.addProject(
      name: 'Sub',
      parentProjectId: parentId,
    );

    await repository.updateProject(id: childId, name: 'Sub renamed');
    var child = (await repository.watchProjects().first).firstWhere(
      (p) => p.id == childId,
    );
    expect(child.name, 'Sub renamed');
    expect(child.parentProjectId, parentId);

    await repository.updateProject(
      id: childId,
      parentProjectId: const Value(null),
    );
    child = (await repository.watchProjects().first).firstWhere(
      (p) => p.id == childId,
    );
    expect(child.parentProjectId, isNull);
  });

  test('deleteProject reassigns its tasks to Inbox and children to top-level', () async {
    final parentId = await repository.addProject(name: 'Work');
    final childId = await repository.addProject(
      name: 'Sub',
      parentProjectId: parentId,
    );
    final taskId = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Standup',
            sortOrder: 0,
            projectId: Value(parentId),
          ),
        );

    await repository.deleteProject(parentId);

    final projects = await repository.watchProjects().first;
    expect(projects.map((p) => p.id), isNot(contains(parentId)));
    final child = projects.firstWhere((p) => p.id == childId);
    expect(child.parentProjectId, isNull);

    final task = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    expect(task.projectId, isNull);
  });

  test('buildProjectTree nests children under their parent, sorted', () async {
    final parentId = await repository.addProject(name: 'Work');
    await repository.addProject(name: 'Personal');
    await repository.addProject(name: 'Sub B', parentProjectId: parentId);
    await repository.addProject(name: 'Sub A', parentProjectId: parentId);

    final tree = buildProjectTree(await repository.watchProjects().first);

    expect(tree.map((n) => n.project.name), ['Work', 'Personal']);
    final work = tree.firstWhere((n) => n.project.name == 'Work');
    expect(work.children.map((n) => n.project.name), ['Sub B', 'Sub A']);
    expect(work.children.first.depth, 1);
  });
}
