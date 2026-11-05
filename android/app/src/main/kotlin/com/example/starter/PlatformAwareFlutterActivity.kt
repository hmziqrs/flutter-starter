package com.example.starter

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

abstract class PlatformAwareFlutterActivity : FlutterActivity() {
    protected abstract val isAuthoritativeTvLaunch: Boolean

    private var platformCapabilitiesChannel: MethodChannel? = null
    private var nativeSurfaces: NativeSurfacesChannel? = null
    private var surfaceLaunchRoute: String? = null

    // Before super, which starts the engine and its plugins: they read this intent.
    override fun onCreate(savedInstanceState: Bundle?) {
        val route = SurfaceRoutes.take(intent)
        surfaceLaunchRoute = route.takeIf { savedInstanceState == null }
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        SurfaceRoutes.take(intent)?.let { nativeSurfaces?.openRoute(it) }
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        platformCapabilitiesChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                PLATFORM_CAPABILITIES_CHANNEL,
            ).also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        IS_ANDROID_TV_METHOD -> result.success(isAndroidTv())
                        else -> result.notImplemented()
                    }
                }
            }
        nativeSurfaces =
            NativeSurfacesChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                this,
                surfaceLaunchRoute,
            )
        surfaceLaunchRoute = null
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        platformCapabilitiesChannel?.setMethodCallHandler(null)
        platformCapabilitiesChannel = null
        nativeSurfaces?.dispose()
        nativeSurfaces = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun isAndroidTv(): Boolean {
        if (isAuthoritativeTvLaunch) {
            return true
        }

        return try {
            packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
        } catch (_: RuntimeException) {
            false
        }
    }

    private companion object {
        const val PLATFORM_CAPABILITIES_CHANNEL = "starter/platform_capabilities"
        const val IS_ANDROID_TV_METHOD = "isAndroidTv"
    }
}
