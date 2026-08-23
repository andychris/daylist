import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/providers/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('add a task and see it appear', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('tapping a task toggles it done', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Toggling this task completes 1/1, which triggers the confetti
    // celebration. confetti-0.8.0's animation controller re-loops until its
    // particle-system physics decide it's "finished" (particles off-screen),
    // which doesn't resolve on the test harness's surface — so we pump a
    // bounded, fixed duration here instead of pumpAndSettle(), which would
    // hang waiting for an animation that never settles in this environment.
    await tester.tap(find.text('Buy milk'));
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
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

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
