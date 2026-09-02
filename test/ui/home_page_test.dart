import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

// Types "today" alongside the title so the quick-add parser gives the task
// a due date of today — otherwise it's an undated Inbox item and won't show
// up on the Today page these tests exercise. The parser strips the
// recognized "today" token back out, so the row still just shows [title].
Future<void> _addTaskViaSheet(WidgetTester tester, String title) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '$title today');
  await tester.tap(find.text('Add task'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('add a task and see it appear', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _addTaskViaSheet(tester, 'Buy milk');

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('an undated task does not appear on Today (goes to Inbox)', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Someday maybe');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Someday maybe'), findsNothing);
    expect(find.text('Nothing due today. Tap + to add a task!'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('tapping a task toggles it done', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    // A recurring task, not a one-off: completing a one-off task archives
    // it (see checklist_repository_test.dart), so it would vanish from the
    // list entirely instead of showing the checked "1/1" state this test
    // is actually after. Typed directly (not via _addTaskViaSheet, which
    // appends "today" — redundant here, and "every day" already makes the
    // parser skip date extraction, so "today" would be left in the title).
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Meditate every day');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    // Toggling this task completes 1/1, which triggers the confetti
    // celebration. confetti-0.8.0's animation controller re-loops until its
    // particle-system physics decide it's "finished" (particles off-screen),
    // which doesn't resolve on the test harness's surface — so we pump a
    // bounded, fixed duration here instead of pumpAndSettle(), which would
    // hang waiting for an animation that never settles in this environment.
    await tester.tap(find.text('Meditate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1/1'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('swiping deletes and undo restores the task', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _addTaskViaSheet(tester, 'Buy milk');

    await tester.drag(find.text('Buy milk'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);

    await disposeCleanly(tester);
  });
}
