package com.santosh.daylist

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * A fixed-row (not RemoteViewsService-backed) home-screen widget: up to
 * [MAX_ROWS] of today's due tasks, each row toggling that task's
 * completion via a background Dart callback (see
 * `today_widget_background_handler.dart`), plus a "+" that launches the
 * app straight into quick-add. The task data itself is written from Dart
 * via `HomeWidget.saveWidgetData` under the `today_tasks` key (a JSON
 * array of `{id, title, done}`, not-done rows first — see
 * `TodayWidgetGateway.updateTodayTasks`).
 */
class TodayWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val MAX_ROWS = 5
        private val taskRowIds =
            intArrayOf(
                R.id.task_row_0,
                R.id.task_row_1,
                R.id.task_row_2,
                R.id.task_row_3,
                R.id.task_row_4,
            )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                RemoteViews(context.packageName, R.layout.today_widget_layout).apply {
                    val addIntent =
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("todaywidget://add"),
                        )
                    setOnClickPendingIntent(R.id.widget_add_button, addIntent)

                    val tasksJson = widgetData.getString("today_tasks", null)
                    val tasks = if (tasksJson != null) JSONArray(tasksJson) else JSONArray()

                    var visibleCount = 0
                    for (i in taskRowIds.indices) {
                        val rowId = taskRowIds[i]
                        if (i < tasks.length() && i < MAX_ROWS) {
                            val task = tasks.getJSONObject(i)
                            val taskId = task.getInt("id")
                            val title = task.getString("title")
                            val done = task.optBoolean("done", false)
                            setTextViewText(rowId, rowText(title, done))
                            setViewVisibility(rowId, View.VISIBLE)
                            val toggleIntent =
                                HomeWidgetBackgroundIntent.getBroadcast(
                                    context,
                                    Uri.parse("todaywidget://complete?taskId=$taskId"),
                                )
                            setOnClickPendingIntent(rowId, toggleIntent)
                            visibleCount++
                        } else {
                            setViewVisibility(rowId, View.GONE)
                        }
                    }
                    setViewVisibility(
                        R.id.widget_empty_text,
                        if (visibleCount == 0) View.VISIBLE else View.GONE,
                    )
                }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * "☑ Title" struck through and greyed out when [done], "☐ Title" in
     * normal text otherwise — the visible confirmation a tap actually did
     * something, which a plain text swap (or no change, for a still-due
     * recurring task) doesn't give the user.
     */
    private fun rowText(title: String, done: Boolean): CharSequence {
        val text = "${if (done) "☑" else "☐"} $title"
        if (!done) return text
        return SpannableString(text).apply {
            setSpan(StrikethroughSpan(), 0, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(
                ForegroundColorSpan(Color.parseColor("#FF808080")),
                0,
                text.length,
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
        }
    }
}
