package com.example.starter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import java.util.concurrent.TimeUnit

/**
 * The lock screen presence: an ongoing notification, promoted to a Live Update on
 * Android 16 and up. Text arrives from Dart, except the channel's name in Settings.
 */
internal object SurfaceLive {
    private const val CHANNEL_ID = "native_surfaces_live"
    private const val NOTIFICATION_ID = 7301
    private const val PROGRESS_MAX = 100
    private const val MAX_ACTIONS = 3

    // Notification.EXTRA_REQUEST_PROMOTED_ONGOING, whose constant arrived in 36.1
    // although Android 16 already reads this extra.
    private const val EXTRA_REQUEST_PROMOTED = "android.requestPromotedOngoing"

    // An app that dies mid session cannot end it, and an ongoing notification would
    // stay until reboot. iOS ends Live Activities after the same eight hours.
    private val TIMEOUT_MILLIS = TimeUnit.HOURS.toMillis(8)

    fun start(context: Context, snapshot: SurfaceSnapshot): Boolean {
        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)) return false
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false
        ensureChannel(context, manager)
        if (manager.getNotificationChannel(CHANNEL_ID)?.importance == NotificationManager.IMPORTANCE_NONE) {
            return false
        }
        SurfaceStore.setLive(context, true)
        manager.notify(NOTIFICATION_ID, build(context, snapshot))
        return true
    }

    /** Does nothing once the session has ended, or the user has dismissed it. */
    fun update(context: Context, snapshot: SurfaceSnapshot) {
        if (!SurfaceStore.isLive(context)) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, build(context, snapshot))
    }

    fun end(context: Context) {
        SurfaceStore.setLive(context, false)
        context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
    }

    private fun ensureChannel(context: Context, manager: NotificationManager) {
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.surface_live_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = context.getString(R.string.surface_live_channel_description)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
        manager.createNotificationChannel(channel)
    }

    private fun build(context: Context, snapshot: SurfaceSnapshot): Notification {
        val builder =
            Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_surface_notification)
                .setColor(context.getColor(snapshot.status.accentColor()))
                // Status first and the project under it, as the brand's live notification reads.
                .setContentTitle(snapshot.subtitle)
                .setContentText(snapshot.title)
                .setSubText(listOfNotNull(snapshot.value, snapshot.valueLabel).joinToString(" ").ifEmpty { null })
                .setContentIntent(SurfaceRoutes.pendingIntent(context, snapshot.route))
                .setDeleteIntent(dismissed(context))
                .setCategory(Notification.CATEGORY_PROGRESS)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setTimeoutAfter(TIMEOUT_MILLIS)
        for (action in snapshot.actions.take(MAX_ACTIONS)) {
            builder.addAction(
                Notification.Action.Builder(
                    null as Icon?,
                    action.label,
                    SurfaceRoutes.pendingIntent(context, action.route),
                ).build(),
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            promote(context, builder, snapshot)
        } else if (snapshot.progress != null) {
            builder.setProgress(PROGRESS_MAX, snapshot.percent(), false)
        }
        return builder.build()
    }

    @Suppress("NewApi")
    private fun promote(
        context: Context,
        builder: Notification.Builder,
        snapshot: SurfaceSnapshot,
    ) {
        builder.addExtras(Bundle().apply { putBoolean(EXTRA_REQUEST_PROMOTED, true) })
        snapshot.value?.let(builder::setShortCriticalText)
        if (snapshot.progress != null) {
            builder.setStyle(
                Notification.ProgressStyle()
                    .setStyledByProgress(true)
                    .setProgress(snapshot.percent())
                    .setProgressSegments(
                        listOf(
                            Notification.ProgressStyle.Segment(PROGRESS_MAX)
                                .setColor(context.getColor(snapshot.status.accentColor())),
                        ),
                    ),
            )
        }
    }

    private fun SurfaceSnapshot.percent(): Int = ((progress ?: 0f) * PROGRESS_MAX).toInt()

    private fun dismissed(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, SurfaceLiveDismissedReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

/** Ends the session when the user swipes the notification away, or it times out. */
class SurfaceLiveDismissedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        SurfaceStore.setLive(context, false)
    }
}
