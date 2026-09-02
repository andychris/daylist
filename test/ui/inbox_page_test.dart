import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('an undated task shows up in Inbox', (tester) async {
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

    await tester.tap(find.byIcon(Icons.inbox_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Someday maybe'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets('empty Inbox shows a placeholder', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides(db),
        child: const DaylistApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.inbox_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Inbox is empty.'), findsOneWidget);

    await disposeCleanly(tester);
  });
}
