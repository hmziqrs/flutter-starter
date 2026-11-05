package com.example.starter

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * The tap-through from a widget or notification into the app. Routes pass through
 * unvalidated, since Dart checks every one against its allowlist.
 */
internal object SurfaceRoutes {
    private const val SCHEME = "starter-surface"
    private const val HOST = "open"
    private const val ROUTE = "route"

    /** Distinct routes get distinct PendingIntents, because the data URI differs. */
    fun pendingIntent(context: Context, route: String): PendingIntent {
        val uri = Uri.Builder().scheme(SCHEME).authority(HOST).appendQueryParameter(ROUTE, route).build()
        val intent =
            Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * The route [intent] asks for, or null. Clears the URL from the intent, because the
     * Flutter engine and app_links would otherwise treat it as a deep link of their own.
     * Reopening from Recents replays the original intent, which must not navigate again.
     */
    fun take(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (data.scheme != SCHEME || data.host != HOST) return null
        intent.data = null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        return data.getQueryParameter(ROUTE)
    }
}
