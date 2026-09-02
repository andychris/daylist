import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../test_utils.dart';

void main() {
  testWidgets('a task due next week shows up in Upcoming, grouped by date', (
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
    await tester.enterText(find.byType(TextField), 'Renew passport in 7 days');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    // Not on Today.
    expect(find.text('Renew passport'), findsNothing);

    await tester.tap(find.byIcon(Icons.upcoming_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Renew passport'), findsOneWidget);
    final expectedDate = DateFormat.MMMEd().format(
      DateTime.now().add(const Duration(days: 7)),
    );
    expect(find.text(expectedDate), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('empty Upcoming shows a placeholder', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.upcoming_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Nothing scheduled ahead.'), findsOneWidget);

    await disposeCleanly(tester);
  });
}
