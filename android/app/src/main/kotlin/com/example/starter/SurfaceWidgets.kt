package com.example.starter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.ColorRes
import androidx.annotation.IdRes

/** Home screen widgets. Both draw every size; they differ in their picker entry and default size. */
abstract class SurfaceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        val snapshot = SurfaceStore.read(context)
        for (id in appWidgetIds) {
            manager.updateAppWidget(id, SurfaceWidgets.views(context, snapshot, manager.getAppWidgetOptions(id)))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        manager.updateAppWidget(appWidgetId, SurfaceWidgets.views(context, SurfaceStore.read(context), newOptions))
    }
}

class SurfaceSmallWidgetProvider : SurfaceWidgetProvider()

class SurfaceMediumWidgetProvider : SurfaceWidgetProvider()

internal object SurfaceWidgets {
    /** Below this height the small layout swaps the gauge for the figure alone. */
    private const val GAUGE_MIN_HEIGHT_DP = 150

    /** From this width up, a widget uses the medium layout. */
    private const val MEDIUM_MIN_WIDTH_DP = 240

    private const val MIN_WIDTH_DP = 100
    private const val MIN_HEIGHT_DP = 100

    // The brand's gauge is drawn on a 180 unit square; surface_gauge_track.xml matches.
    private const val GAUGE_UNITS = 180f
    private const val GAUGE_RADIUS = 62f
    private const val GAUGE_STROKE = 7f
    private const val GAUGE_SIZE_DP = 120
    private const val FULL_SWEEP = 360f
    private const val TOP_OF_CIRCLE = -90f

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val snapshot = SurfaceStore.read(context)
        for (provider in listOf(SurfaceSmallWidgetProvider::class.java, SurfaceMediumWidgetProvider::class.java)) {
            for (id in manager.getAppWidgetIds(ComponentName(context, provider))) {
                manager.updateAppWidget(id, views(context, snapshot, manager.getAppWidgetOptions(id)))
            }
        }
    }

    fun views(context: Context, snapshot: SurfaceSnapshot, options: Bundle): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(
                mapOf(
                    SizeF(MIN_WIDTH_DP.toFloat(), MIN_HEIGHT_DP.toFloat()) to small(context, snapshot, gauge = false),
                    SizeF(MIN_WIDTH_DP.toFloat(), GAUGE_MIN_HEIGHT_DP.toFloat()) to small(context, snapshot, gauge = true),
                    SizeF(MEDIUM_MIN_WIDTH_DP.toFloat(), MIN_HEIGHT_DP.toFloat()) to medium(context, snapshot),
                ),
            )
        }
        // Before Android 12 the launcher reports a range; a phone in portrait uses
        // the minimum width and the maximum height.
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        return when {
            width >= MEDIUM_MIN_WIDTH_DP -> medium(context, snapshot)
            else -> small(context, snapshot, gauge = height >= GAUGE_MIN_HEIGHT_DP)
        }
    }

    private fun small(context: Context, snapshot: SurfaceSnapshot, gauge: Boolean): RemoteViews =
        RemoteViews(context.packageName, R.layout.surface_widget_small).also {
            bind(context, it, snapshot, showGauge = gauge && snapshot.progress != null)
        }

    private fun medium(context: Context, snapshot: SurfaceSnapshot): RemoteViews =
        RemoteViews(context.packageName, R.layout.surface_widget_medium).also {
            bind(context, it, snapshot, showGauge = snapshot.progress != null)
            bindActions(context, it, snapshot)
        }

    private fun bind(context: Context, views: RemoteViews, snapshot: SurfaceSnapshot, showGauge: Boolean) {
        views.setOnClickPendingIntent(android.R.id.background, SurfaceRoutes.pendingIntent(context, snapshot.route))
        views.setTextViewText(R.id.surface_title, snapshot.title)
        views.setTint(context, R.id.surface_dot, snapshot.status.dotColor())

        views.setVisible(R.id.surface_gauge, showGauge)
        if (showGauge) {
            views.setImageViewBitmap(R.id.surface_gauge_arc, gaugeArc(context, snapshot.progress ?: 0f))
            views.setTint(context, R.id.surface_gauge_arc, snapshot.status.accentColor())
            views.setText(R.id.surface_gauge_value, snapshot.value)
            views.setText(R.id.surface_gauge_label, snapshot.valueLabel)
        }

        val showStat = !showGauge && snapshot.value != null
        views.setVisible(R.id.surface_stat, showStat)
        if (showStat) {
            views.setText(R.id.surface_stat_value, snapshot.value)
            views.setText(R.id.surface_stat_label, snapshot.valueLabel)
        }

        // Beside a gauge the subtitle is the headline, as the brand's status line is.
        // Under a figure, or alone, it is a caption.
        views.setText(R.id.surface_subtitle_strong, snapshot.subtitle.takeIf { showGauge })
        views.setText(R.id.surface_subtitle_muted, snapshot.subtitle.takeUnless { showGauge })
    }

    private fun bindActions(context: Context, views: RemoteViews, snapshot: SurfaceSnapshot) {
        val cells = listOf(R.id.surface_action_1, R.id.surface_action_2, R.id.surface_action_3)
        views.setVisible(R.id.surface_actions, snapshot.actions.isNotEmpty())
        cells.forEachIndexed { index, cell ->
            val action = snapshot.actions.getOrNull(index)
            views.setText(cell, action?.label)
            if (action != null) {
                views.setOnClickPendingIntent(cell, SurfaceRoutes.pendingIntent(context, action.route))
            }
        }
    }

    /** Sets [text] on a view, hiding the view when there is none. */
    private fun RemoteViews.setText(@IdRes id: Int, text: String?) {
        setVisible(id, text != null)
        setTextViewText(id, text.orEmpty())
    }

    private fun RemoteViews.setVisible(@IdRes id: Int, visible: Boolean) {
        setViewVisibility(id, if (visible) View.VISIBLE else View.GONE)
    }

    /**
     * Tints from a color resource, so Android 12 and up resolves it against the
     * launcher's light or dark mode when the widget is drawn. Older versions take
     * the current mode's color, which holds until the next publish.
     */
    private fun RemoteViews.setTint(context: Context, @IdRes id: Int, @ColorRes color: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            setColorStateList(id, "setImageTintList", color)
        } else {
            setInt(id, "setColorFilter", context.getColor(color))
        }
    }

    /** The arc as an alpha mask, because a drawable resource cannot round its caps. */
    private fun gaugeArc(context: Context, progress: Float): Bitmap {
        val size = (GAUGE_SIZE_DP * context.resources.displayMetrics.density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ALPHA_8)
        if (progress <= 0f) return bitmap
        val unit = size / GAUGE_UNITS
        val paint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
                strokeWidth = GAUGE_STROKE * unit
            }
        val center = size / 2f
        val radius = GAUGE_RADIUS * unit
        Canvas(bitmap).drawArc(
            RectF(center - radius, center - radius, center + radius, center + radius),
            TOP_OF_CIRCLE,
            FULL_SWEEP * progress,
            false,
            paint,
        )
        return bitmap
    }
}

/** The gauge, the notification's accent and its progress bar follow the status. */
@ColorRes
internal fun SurfaceStatus.accentColor(): Int =
    when (this) {
        SurfaceStatus.IDLE, SurfaceStatus.ACTIVE -> R.color.surface_accent
        SurfaceStatus.SUCCESS -> R.color.surface_success
        SurfaceStatus.WARNING -> R.color.surface_warning
        SurfaceStatus.FAILURE -> R.color.surface_failure
    }

/** The small status dot. Idle stays quiet instead of borrowing the accent. */
@ColorRes
internal fun SurfaceStatus.dotColor(): Int =
    if (this == SurfaceStatus.IDLE) R.color.surface_muted else accentColor()
