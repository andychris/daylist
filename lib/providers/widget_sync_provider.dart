import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/widget/today_widget_gateway.dart';
import 'checklist_providers.dart';

final todayWidgetGatewayProvider = Provider<TodayWidgetGateway>((ref) {
  return TodayWidgetGateway();
});

/// A side-effect-only provider — watching it (see [HomePage]) keeps the
/// Android home-screen widget's task rows in sync with Today's, without
/// the widget needing its own DB query.
final widgetSyncProvider = Provider<void>((ref) {
  final groupedAsync = ref.watch(groupedTasksProvider);
  groupedAsync.whenData((grouped) {
    final onPlate = [...grouped.overdue, ...grouped.dueToday]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    ref.read(todayWidgetGatewayProvider).updateTodayTasks(onPlate);
  });
});
