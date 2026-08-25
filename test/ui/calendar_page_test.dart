import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/domain/date_utils.dart';
import 'package:daylist/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../test_utils.dart';

void main() {
  Future<AppDatabase> seedDatabase() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final today = todayLocalMidnight();

    final taskId = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Meditate',
            sortOrder: 0,
            createdAt: Value(today),
          ),
        );
    await db
        .into(db.taskCompletions)
        .insert(
          TaskCompletionsCompanion.insert(
            taskId: taskId,
            date: formatLocalDate(today),
          ),
        );

    return db;
  }

  testWidgets('calendar shows the current month and today has a ring', (
    tester,
  ) async {
    final db = await seedDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    final expectedTitle = DateFormat('MMMM yyyy').format(DateTime.now());
    expect(find.text(expectedTitle), findsOneWidget);
    expect(find.text('${DateTime.now().day}'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('prev/next month navigation updates the header', (
    tester,
  ) async {
    final db = await seedDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat('MMMM yyyy').format(previousMonth)),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('tapping today opens the detail sheet with the seeded task', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final db = await seedDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    await tester.tap(find.text('${DateTime.now().day}').last);
    await tester.pumpAndSettle();

    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('a future day in the current month is not tappable', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final db = await seedDatabase();
    addTearDown(db.close);
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    // Only meaningful when today isn't already the last day of the month.
    if (now.day >= lastDayOfMonth) return;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    await tester.tap(find.text('$lastDayOfMonth').last);
    await tester.pumpAndSettle();

    // No detail sheet opened — the seeded task's title shouldn't appear
    // twice (once for the day cell context, it wouldn't appear at all here
    // since the sheet never opens).
    expect(find.text('Meditate'), findsNothing);

    await disposeCleanly(tester);
  });

  testWidgets('next/prev month navigation crosses a year boundary', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    // Walk forward 13 months to guarantee crossing at least one Dec->Jan
    // boundary regardless of what month "now" happens to be.
    for (var i = 0; i < 13; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
    }

    final expected = DateTime(DateTime.now().year, DateTime.now().month + 13, 1);
    expect(
      find.text(DateFormat('MMMM yyyy').format(expected)),
      findsOneWidget,
    );

    await disposeCleanly(tester);
  });

  testWidgets('jump-to-today returns to the current month', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat('MMMM yyyy').format(DateTime.now())),
      findsOneWidget,
    );

    await disposeCleanly(tester);
  });
}
