package com.example.starter

import android.content.Context
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

internal enum class SurfaceStatus { IDLE, ACTIVE, SUCCESS, WARNING, FAILURE }

internal data class SurfaceAction(val label: String, val route: String)

/** What Dart published, as docs/native_surfaces.md defines it. */
internal data class SurfaceSnapshot(
    val title: String,
    val subtitle: String,
    val value: String? = null,
    val valueLabel: String? = null,
    val progress: Float? = null,
    val status: SurfaceStatus = SurfaceStatus.IDLE,
    val route: String = "/",
    val actions: List<SurfaceAction> = emptyList(),
) {
    companion object {
        private const val KNOWN_SCHEMA = 1

        /** The contract's text for when nothing readable has been published. */
        fun fallback(context: Context) =
            SurfaceSnapshot(
                title = context.getString(R.string.app_name),
                subtitle = context.getString(R.string.surface_fallback_subtitle),
            )

        /** Null when [json] is malformed, or from a schema newer than this build knows. */
        fun parse(json: String): SurfaceSnapshot? =
            try {
                val root = JSONObject(json)
                if (root.getInt("schema") > KNOWN_SCHEMA) {
                    null
                } else {
                    SurfaceSnapshot(
                        title = root.getString("title"),
                        subtitle = root.getString("subtitle"),
                        value = root.optionalString("value"),
                        valueLabel = root.optionalString("valueLabel"),
                        progress = root.optionalProgress(),
                        status = statusNamed(root.optionalString("status")),
                        route = root.optionalString("route") ?: "/",
                        actions = root.optJSONArray("actions").toActions(),
                    )
                }
            } catch (_: JSONException) {
                null
            }

        fun parseOrFallback(context: Context, json: String?): SurfaceSnapshot =
            json?.let(::parse) ?: fallback(context)

        private fun JSONObject.optionalString(key: String): String? =
            if (isNull(key)) null else getString(key)

        private fun JSONObject.optionalProgress(): Float? =
            if (isNull("progress")) null else getDouble("progress").toFloat().coerceIn(0f, 1f)

        private fun statusNamed(name: String?): SurfaceStatus =
            when (name) {
                "active" -> SurfaceStatus.ACTIVE
                "success" -> SurfaceStatus.SUCCESS
                "warning" -> SurfaceStatus.WARNING
                "failure" -> SurfaceStatus.FAILURE
                else -> SurfaceStatus.IDLE
            }

        private fun JSONArray?.toActions(): List<SurfaceAction> {
            if (this == null) return emptyList()
            return List(length()) { index ->
                val action = getJSONObject(index)
                SurfaceAction(action.getString("label"), action.getString("route"))
            }
        }
    }
}

/** The storage the contract names: file `native_surfaces`, key `snapshot`. */
internal object SurfaceStore {
    private const val FILE = "native_surfaces"
    private const val KEY_SNAPSHOT = "snapshot"
    private const val KEY_LIVE = "live"

    private fun preferences(context: Context) =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun write(context: Context, json: String) {
        preferences(context).edit().putString(KEY_SNAPSHOT, json).apply()
    }

    fun read(context: Context): SurfaceSnapshot =
        SurfaceSnapshot.parseOrFallback(
            context,
            preferences(context).getString(KEY_SNAPSHOT, null),
        )

    fun isLive(context: Context): Boolean = preferences(context).getBoolean(KEY_LIVE, false)

    fun setLive(context: Context, live: Boolean) {
        preferences(context).edit().putBoolean(KEY_LIVE, live).apply()
    }
}
