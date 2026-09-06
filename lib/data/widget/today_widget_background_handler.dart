import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../../domain/date_utils.dart';
import '../../domain/task_grouping.dart';
import '../database/app_database.dart';
import '../notifications/flutter_local_notifications_gateway.dart';
import '../notifications/notification_scheduler.dart';
import '../repositories/checklist_repository.dart';
import 'today_widget_gateway.dart';

/// Mirrors `task_row.dart`'s completionAnimationDelay — the widget has no
/// animation, but pushing an optimistic "checked" state before the real
/// write gives the same brief visible confirmation instead of a one-off
/// task (which archives on completion) just vanishing from the row list.
const _completionConfirmDelay = Duration(milliseconds: 450);

/// Handles a tap on the home-screen widget while the app isn't running —
/// registered once via `HomeWidget.registerInteractivityCallback` (see
/// `main.dart`). Must be a top-level function annotated exactly like this
/// (the package's own dispatcher looks it up by callback handle), and
/// opens its own short-lived [AppDatabase] connection for the same reason
/// `notification_background_handler.dart` does.
@pragma('vm:entry-point')
Future<void> todayWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'complete') return;
  final taskId = int.tryParse(uri.queryParameters['taskId'] ?? '');
  if (taskId == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  try {
    final scheduler = NotificationScheduler(FlutterLocalNotificationsGateway());
    final repository = ChecklistRepository(db, scheduler);
    final today = DateTime.now();
    final dateKey = formatLocalDate(today);

    // Read the task's actual current state rather than assuming "not done
    // yet" — the row tapped might already be showing checked (the widget
    // renders both done and not-done rows so recurring tasks give visible
    // feedback), in which case this tap means "undo", not "complete".
    final existingCompletion =
        await (db.select(db.taskCompletions)..where(
              (c) => c.taskId.equals(taskId) & c.date.equals(dateKey),
            ))
            .getSingleOrNull();
    final isCurrentlyDone = existingCompletion != null;

    if (!isCurrentlyDone) {
      // Optimistic confirmation before the real write — un-checking skips
      // this, same as the in-app rows.
      await _refreshWidget(repository, optimisticallyDoneTaskId: taskId);
      await Future.delayed(_completionConfirmDelay);
    }

    await repository.toggleCompletion(
      taskId: taskId,
      localDate: today,
      isCurrentlyDone: isCurrentlyDone,
    );

    await _refreshWidget(repository);
  } finally {
    await db.close();
  }
}

/// Re-reads today's due tasks and pushes them to the widget — called after
/// a background completion so the row that was just tapped actually
/// reflects its new state rather than waiting for the app to next be
/// opened. [optimisticallyDoneTaskId], if given, renders that task as done
/// even though the DB doesn't say so yet (see the delay above).
Future<void> _refreshWidget(
  ChecklistRepository repository, {
  int? optimisticallyDoneTaskId,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tasks = await repository.watchChecklistForDate(today).first;
  final grouped = groupTasksByDueness(tasks, today);
  var onPlate = [...grouped.overdue, ...grouped.dueToday];
  if (optimisticallyDoneTaskId != null) {
    onPlate = [
      for (final t in onPlate)
        if (t.id == optimisticallyDoneTaskId) t.copyWith(isDoneToday: true) else t,
    ];
  }
  await TodayWidgetGateway().updateTodayTasks(onPlate);
}
