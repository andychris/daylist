import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('creating a project and a task inside it shows the task there', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();
    expect(find.text('No projects yet. Tap + to add one!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Launch');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Launch'), findsOneWidget);
    await tester.tap(find.text('Launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Design mockups');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Design mockups'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('switching a project to board view shows the Kanban columns', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.projects)
        .insert(ProjectsCompanion.insert(name: 'Launch', sortOrder: 0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();

    expect(find.text('No section (0)'), findsOneWidget);
    expect(find.text('Add section'), findsOneWidget);

    await disposeCleanly(tester);
  });
}
