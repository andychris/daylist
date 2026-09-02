import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'data/widget/today_widget_background_handler.dart';
import 'providers/database_provider.dart';
import 'providers/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Reconcile scheduled notifications against current task state at
  // startup — the OS can silently drop scheduled notifications (a
  // force-stop, reinstall, or timezone change), so this is the safety net.
  await container.read(notificationsGatewayProvider).initialize();
  final db = container.read(databaseProvider);
  final allTasks = await db.select(db.tasks).get();
  await container.read(notificationSchedulerProvider).reconcileAll(allTasks);

  // Lets the home-screen widget's "Complete" row tap run
  // todayWidgetBackgroundCallback without opening the app.
  await HomeWidget.registerInteractivityCallback(todayWidgetBackgroundCallback);

  runApp(
    UncontrolledProviderScope(container: container, child: const DaylistApp()),
  );
}
