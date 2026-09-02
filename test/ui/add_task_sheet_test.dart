import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/domain/models/task_priority.dart';
import 'package:daylist/ui/home/widgets/animated_checkbox.dart';
import 'package:daylist/ui/theme/task_priority_style.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  testWidgets('picking a priority colors the new task\'s checkbox', (
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

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ship the release');
    // warnIfMissed: false — the ChoiceChip's avatar icon and label sit in
    // the same InkWell, so a center-of-text tap can register a fraction of
    // a pixel outside the label's own RenderParagraph; the chip still
    // receives and handles the tap (proven below by the resulting color).
    await tester.tap(find.text('P1'), warnIfMissed: false);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<AnimatedCheckbox>(
      find.byType(AnimatedCheckbox),
    );
    expect(checkbox.activeColor, TaskPriority.p1.color);

    await disposeCleanly(tester);
  });

  testWidgets('picking a project shows its name as a badge on the row', (
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

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ship the release');
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Launch').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Launch'), findsOneWidget);

    await disposeCleanly(tester);
  });
}
