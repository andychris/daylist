import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../domain/models/checklist_item.dart';

const todayWidgetAndroidName = 'TodayWidgetProvider';

/// Maximum rows the fixed (non-`RemoteViewsService`-backed) widget layout
/// has — see `TodayWidgetProvider.kt`. A day with more due tasks than this
/// just shows the first [maxRows]; a scrolling collection widget would be
/// the natural next step if that turns out to matter in practice.
const maxRows = 5;

/// Pushes today's due tasks to the Android home-screen widget's storage
/// and asks it to redraw. Cheap to call on every relevant change — it's
/// just a SharedPreferences write plus a broadcast, not a rebuild of
/// anything expensive.
class TodayWidgetGateway {
  Future<void> updateTodayTasks(List<ChecklistItem> tasks) async {
    final rows = tasks
        .take(maxRows)
        .map((t) => {'id': t.id, 'title': t.title})
        .toList();
    await HomeWidget.saveWidgetData<String>('today_tasks', jsonEncode(rows));
    await HomeWidget.updateWidget(androidName: todayWidgetAndroidName);
  }
}
