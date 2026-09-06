import 'package:daylist/app.dart';
import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/ui/widgets/task_row.dart' show completionAnimationDelay;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

// The Today screen's "+" defaults an otherwise-undated task to today (see
// AddTaskSheet.defaultDueDate) — so a plain title added from here shows up
// immediately, matching how the app is actually used day to day.
Future<void> _addTaskViaSheet(WidgetTester tester, String title) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), title);
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

  testWidgets(
    'an undated task added from Inbox does not appear on Today, but is in Inbox',
    (tester) async {
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
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Someday maybe');
      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();

      expect(find.text('Someday maybe'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Someday maybe'), findsNothing);
      expect(find.text('Nothing due today. Tap + to add a task!'), findsOneWidget);

      await disposeCleanly(tester);
    },
  );

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
    // is actually after.
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
    // That duration also has to clear TaskRow's completionAnimationDelay —
    // the real DB write (and so the "1/1" this asserts on) doesn't happen
    // until after it.
    await tester.tap(find.text('Meditate'));
    await tester.pump();
    await tester.pump(completionAnimationDelay + const Duration(milliseconds: 300));

    expect(find.text('1/1'), findsOneWidget);

    await disposeCleanly(tester);
  });

  testWidgets(
    'completing a one-off task shows strikethrough briefly before it archives',
    (tester) async {
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

      await tester.tap(find.text('Buy milk'));
      await tester.pump();

      // Still visible, now struck through — the optimistic state, before
      // the real (archiving) DB write has happened.
      expect(find.text('Buy milk'), findsOneWidget);
      final styles = tester
          .widgetList<AnimatedDefaultTextStyle>(
            find.ancestor(
              of: find.text('Buy milk'),
              matching: find.byType(AnimatedDefaultTextStyle),
            ),
          )
          .map((w) => w.style);
      expect(
        styles.any((s) => s.decoration == TextDecoration.lineThrough),
        isTrue,
      );

      // Past the delay, the real write lands and the (now archived) task
      // is gone from the list.
      await tester.pump(completionAnimationDelay + const Duration(milliseconds: 300));
      expect(find.text('Buy milk'), findsNothing);

      await disposeCleanly(tester);
    },
  );

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
