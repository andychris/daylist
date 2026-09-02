import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../notifications/flutter_local_notifications_gateway.dart';
import '../notifications/notification_scheduler.dart';
import '../repositories/checklist_repository.dart';
import '../../domain/task_grouping.dart';
import 'today_widget_gateway.dart';

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

    await repository.toggleCompletion(
      taskId: taskId,
      localDate: DateTime.now(),
      isCurrentlyDone: false,
    );

    await _refreshWidget(repository);
  } finally {
    await db.close();
  }
}

/// Re-reads today's due tasks and pushes them to the widget — called after
/// a background completion so the row that was just tapped actually
/// disappears rather than waiting for the app to next be opened.
Future<void> _refreshWidget(ChecklistRepository repository) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tasks = await repository.watchChecklistForDate(today).first;
  final grouped = groupTasksByDueness(tasks, today);
  final onPlate = [...grouped.overdue, ...grouped.dueToday]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  await TodayWidgetGateway().updateTodayTasks(onPlate);
}
