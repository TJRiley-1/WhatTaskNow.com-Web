package com.whatnow.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WhatNowWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.whatnow_widget)
            val taskName = widgetData.getString("task_name", "No task available")
            views.setTextViewText(R.id.widget_task_name, taskName)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
