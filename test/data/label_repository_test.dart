import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/data/repositories/label_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LabelRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LabelRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertTask(String title) {
    return db
        .into(db.tasks)
        .insert(TasksCompanion.insert(title: title, sortOrder: 0));
  }

  test('labels are sorted by name', () async {
    await repository.addLabel(name: 'urgent');
    await repository.addLabel(name: 'errand');

    final labels = await repository.watchLabels().first;
    expect(labels.map((l) => l.name), ['errand', 'urgent']);
  });

  test('setTaskLabels attaches labels and watchLabelsForTask reflects them', () async {
    final taskId = await insertTask('Buy milk');
    final urgentId = await repository.addLabel(name: 'urgent');
    final errandId = await repository.addLabel(name: 'errand');

    await repository.setTaskLabels(taskId, [urgentId, errandId]);

    final labels = await repository.watchLabelsForTask(taskId).first;
    expect(labels.map((l) => l.name), containsAll(['urgent', 'errand']));
  });

  test('setTaskLabels replaces the previous set rather than appending', () async {
    final taskId = await insertTask('Buy milk');
    final urgentId = await repository.addLabel(name: 'urgent');
    final errandId = await repository.addLabel(name: 'errand');

    await repository.setTaskLabels(taskId, [urgentId]);
    await repository.setTaskLabels(taskId, [errandId]);

    final labels = await repository.watchLabelsForTask(taskId).first;
    expect(labels.map((l) => l.name), ['errand']);
  });

  test('deleteLabel removes it from any tasks it was attached to', () async {
    final taskId = await insertTask('Buy milk');
    final urgentId = await repository.addLabel(name: 'urgent');
    await repository.setTaskLabels(taskId, [urgentId]);

    await repository.deleteLabel(urgentId);

    expect(await repository.watchLabels().first, isEmpty);
    expect(await repository.watchLabelsForTask(taskId).first, isEmpty);
  });
}
