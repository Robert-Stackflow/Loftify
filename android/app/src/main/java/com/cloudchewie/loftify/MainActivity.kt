package com.cloudchewie.loftify;

import android.os.Build
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant.*

class MainActivity : FlutterFragmentActivity() {
    private val backDesktopChannel = "android/back/desktop"
    private val displayModeChannel = "loftify/display_mode"
    private var preferredRefreshRate = 0f

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        registerWith(flutterEngine);
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backDesktopChannel
        ).setMethodCallHandler { methodCall, result ->
            if (methodCall.method == "backDesktop") {
                result.success(true)
                moveTaskToBack(false)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            displayModeChannel
        ).setMethodCallHandler { methodCall, result ->
            if (methodCall.method != "setPreferredRefreshRate") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val refreshRate =
                (methodCall.argument<Number>("refreshRate"))?.toFloat()
            if (refreshRate == null || refreshRate < 0f) {
                result.error(
                    "invalid_refresh_rate",
                    "refreshRate must be zero or a positive number",
                    null
                )
                return@setMethodCallHandler
            }
            preferredRefreshRate = refreshRate
            applyPreferredRefreshRate()
            result.success(null)
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        applyPreferredRefreshRate()
    }

    private fun applyPreferredRefreshRate() {
        val attributes = window.attributes
        attributes.preferredRefreshRate = preferredRefreshRate
        window.attributes = attributes

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        window.decorView.post {
            val surfaceView = findFlutterSurfaceView(window.decorView) ?: return@post
            applySurfaceFrameRate(surfaceView)
        }
    }

    private fun applySurfaceFrameRate(surfaceView: SurfaceView) {
        val surface = surfaceView.holder.surface
        if (surface.isValid) {
            surface.setFrameRate(
                preferredRefreshRate,
                Surface.FRAME_RATE_COMPATIBILITY_DEFAULT
            )
            return
        }
        surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                holder.surface.setFrameRate(
                    preferredRefreshRate,
                    Surface.FRAME_RATE_COMPATIBILITY_DEFAULT
                )
                holder.removeCallback(this)
            }

            override fun surfaceChanged(
                holder: SurfaceHolder,
                format: Int,
                width: Int,
                height: Int
            ) = Unit

            override fun surfaceDestroyed(holder: SurfaceHolder) = Unit
        })
    }

    private fun findFlutterSurfaceView(view: View): SurfaceView? {
        if (
            view is SurfaceView &&
            view.javaClass.name == "io.flutter.embedding.android.FlutterSurfaceView"
        ) {
            return view
        }
        if (view !is ViewGroup) return null
        for (index in 0 until view.childCount) {
            val match = findFlutterSurfaceView(view.getChildAt(index))
            if (match != null) return match
        }
        return null
    }
}
