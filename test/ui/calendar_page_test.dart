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
}
