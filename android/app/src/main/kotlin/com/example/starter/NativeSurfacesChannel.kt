package com.example.starter

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** The `starter/native_surfaces` channel, one per Flutter engine. */
internal class NativeSurfacesChannel(
    messenger: BinaryMessenger,
    context: Context,
    launchRoute: String?,
) : MethodChannel.MethodCallHandler {
    private val context = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    private var pendingRoute = launchRoute

    // Dart subscribes to openRoute before it calls takeLaunchRoute, so until that
    // call arrives a tap has to wait with the launch route, or it would be lost.
    private var dartIsListening = false

    fun openRoute(route: String) {
        if (dartIsListening) {
            channel.invokeMethod(OPEN_ROUTE, route)
        } else {
            pendingRoute = route
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "publish" -> {
                SurfaceStore.write(context, call.arguments as String)
                SurfaceWidgets.updateAll(context)
                result.success(null)
            }
            "startLive" -> result.success(SurfaceLive.start(context, snapshot(call)))
            "updateLive" -> {
                SurfaceLive.update(context, snapshot(call))
                result.success(null)
            }
            "endLive" -> {
                SurfaceLive.end(context)
                result.success(null)
            }
            "takeLaunchRoute" -> {
                dartIsListening = true
                result.success(pendingRoute)
                pendingRoute = null
            }
            else -> result.notImplemented()
        }
    }

    private fun snapshot(call: MethodCall) =
        SurfaceSnapshot.parseOrFallback(context, call.arguments as? String)

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private companion object {
        const val CHANNEL = "starter/native_surfaces"
        const val OPEN_ROUTE = "openRoute"
    }
}
