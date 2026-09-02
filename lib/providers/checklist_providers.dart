import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/checklist_repository.dart';
import '../domain/models/checklist_item.dart';
import '../domain/task_grouping.dart';
import 'database_provider.dart';
import 'date_provider.dart';
import 'notification_providers.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationSchedulerProvider),
  );
});

/// Every currently-active task (any project, any schedule), joined against
/// today's per-date completion state. Ungrouped — see
/// [groupedTasksProvider] for the Overdue/Today/Upcoming/Inbox split the UI
/// actually renders.
final todayChecklistProvider = StreamProvider<List<ChecklistItem>>((ref) {
  final today = ref.watch(currentLocalDateProvider);
  return ref.watch(checklistRepositoryProvider).watchChecklistForDate(today);
});

final groupedTasksProvider = Provider<AsyncValue<GroupedTasks>>((ref) {
  final today = ref.watch(currentLocalDateProvider);
  final tasksAsync = ref.watch(todayChecklistProvider);
  return tasksAsync.whenData((tasks) => groupTasksByDueness(tasks, today));
});
