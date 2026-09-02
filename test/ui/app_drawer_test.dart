import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
  }

  testWidgets('adding a label from the drawer and navigating to its page', (
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

    await openDrawer(tester);
    await tester.tap(find.text('Labels'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add label'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'urgent');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // The dialog closing pops only itself — the drawer (still showing
    // Labels expanded) is untouched, so the new label is right there.
    await tester.tap(find.text('urgent'));
    await tester.pumpAndSettle();

    expect(find.text('@urgent'), findsOneWidget);
    expect(find.text('No tasks with this label.'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('adding a filter from the drawer and seeing it match a task', (
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

    // A p1 task due today.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ship release today p1');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'P1 today');
    await tester.enterText(find.widgetWithText(TextField, 'Query'), 'p1 & today');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // The dialog closing pops only itself — the drawer (still showing
    // Filters expanded) is untouched, so the new filter is right there.
    await tester.tap(find.text('P1 today'));
    await tester.pumpAndSettle();

    expect(find.text('Ship release'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('an invalid filter query is rejected with an error', (
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

    await openDrawer(tester);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Broken');
    await tester.enterText(find.widgetWithText(TextField, 'Query'), 'p1 & banana');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unrecognized text'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('toggling dark mode switches the app theme', (tester) async {
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

    await openDrawer(tester);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.system);

    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();

    final updated = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(updated.themeMode, ThemeMode.dark);

    await disposeCleanly(tester);
  });
}
