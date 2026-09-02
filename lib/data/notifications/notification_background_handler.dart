import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/app_database.dart';
import '../repositories/checklist_repository.dart';
import 'flutter_local_notifications_gateway.dart';
import 'notification_action_ids.dart';
import 'notification_scheduler.dart';

/// Runs on Android's background isolate when the user taps Complete/Snooze
/// on a task reminder while the app isn't running — must be a top-level
/// function annotated exactly like this, or the Dart compiler strips it as
/// unused and the platform's callback registration silently does nothing.
@pragma('vm:entry-point')
void notificationBackgroundResponseHandler(NotificationResponse response) {
  handleNotificationAction(response.actionId, response.id);
}

/// The actual Complete/Snooze logic, shared by the background handler
/// above and the foreground one in `FlutterLocalNotificationsGateway`.
/// Opens its own short-lived [AppDatabase] connection (the same
/// underlying file the running app uses) rather than reaching into any
/// existing app state, since a background-isolate tap may have no running
/// app instance to reach into at all.
void handleNotificationAction(String? actionId, int? taskId) {
  if (actionId == null || taskId == null) return;
  // The platform callback signature is synchronous (`void
  // Function(NotificationResponse)`), so the async work below just runs
  // to completion on its own rather than being awaited here.
  unawaited(_run(actionId, taskId));
}

Future<void> _run(String actionId, int taskId) async {
  final db = AppDatabase();
  try {
    final gateway = FlutterLocalNotificationsGateway();
    final scheduler = NotificationScheduler(gateway);
    final repository = ChecklistRepository(db, scheduler);

    final task = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (task == null) return;

    if (actionId == completeActionId) {
      await repository.toggleCompletion(
        taskId: taskId,
        localDate: DateTime.now(),
        isCurrentlyDone: false,
      );
      // A recurring task with a one-shot-style rule (no native repeat)
      // needs its next occurrence scheduled explicitly now that today's
      // has been handled; 'daily'/'weekly:X' already repeat on their own.
      final updated = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingleOrNull();
      if (updated != null) {
        await scheduler.rescheduleNextOccurrence(updated, after: DateTime.now());
      }
    } else if (actionId == snoozeActionId && task.reminderMinuteOfDay != null) {
      await gateway.scheduleOnce(
        id: taskId,
        title: 'daylist',
        body: task.title,
        at: DateTime.now().add(const Duration(hours: 1)),
      );
    }
  } finally {
    await db.close();
  }
}
