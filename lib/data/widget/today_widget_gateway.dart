import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../domain/models/checklist_item.dart';

const todayWidgetAndroidName = 'TodayWidgetProvider';

/// Maximum rows the fixed (non-`RemoteViewsService`-backed) widget layout
/// has — see `TodayWidgetProvider.kt`. A day with more due tasks than this
/// just shows the first [maxRows] (not-yet-done ones first, see
/// [updateTodayTasks]); a scrolling collection widget would be the natural
/// next step if that turns out to matter in practice.
const maxRows = 5;

/// Pushes today's due tasks to the Android home-screen widget's storage
/// and asks it to redraw. Cheap to call on every relevant change — it's
/// just a SharedPreferences write plus a broadcast, not a rebuild of
/// anything expensive.
class TodayWidgetGateway {
  Future<void> updateTodayTasks(List<ChecklistItem> tasks) async {
    // Not-done tasks first (so they stay visible within the row cap even
    // on a busy day), each group by sortOrder — a done task still gets a
    // row when there's room, so completing one from the widget actually
    // shows a checked state instead of just... nothing visibly changing.
    final ordered = [...tasks]..sort((a, b) {
      if (a.isDoneToday != b.isDoneToday) {
        return a.isDoneToday ? 1 : -1;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    final rows = ordered
        .take(maxRows)
        .map((t) => {'id': t.id, 'title': t.title, 'done': t.isDoneToday})
        .toList();
    await HomeWidget.saveWidgetData<String>('today_tasks', jsonEncode(rows));
    await HomeWidget.updateWidget(androidName: todayWidgetAndroidName);
  }
}
