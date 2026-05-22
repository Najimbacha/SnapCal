package com.snapcal.snapcal

import android.os.Bundle
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.TimeZone

class MainActivity : FlutterFragmentActivity() {
    private val timeZoneChannel = "snapcal/timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        Log.i("SnapCalMainActivity", "Generated Flutter plugins registered")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timeZoneChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimeZone" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for Android 15+ (SDK 35) compatibility.
        // This replaces the deprecated setStatusBarColor / setNavigationBarColor APIs.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
