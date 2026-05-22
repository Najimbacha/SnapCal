package com.snapcal.snapcal

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SnapCalWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            val isLocked = widgetData.getBoolean("is_locked", true)
            if (isLocked) {
                views.setTextViewText(R.id.widget_calories, "🔒")
                views.setTextViewText(R.id.widget_status, "Unlock Pro widget")
            } else {
                val remaining = widgetData.getInt("remaining_calories", 2000)
                val status = widgetData.getString("calorie_status", "On track") ?: "On track"
                
                views.setTextViewText(R.id.widget_calories, remaining.toString())
                views.setTextViewText(R.id.widget_status, status)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
