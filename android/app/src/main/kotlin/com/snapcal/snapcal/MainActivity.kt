package com.snapcal.snapcal

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
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
    private val healthConnectChannel = "snapcal/health_connect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        Log.i("SnapCalMainActivity", "Generated Flutter plugins registered")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timeZoneChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimeZone" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, healthConnectChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openHealthConnectSettings" -> {
                    openHealthConnectSettings()
                    result.success(null)
                }
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

    private fun openHealthConnectSettings() {
        val settingsIntent = Intent("android.health.connect.action.HEALTH_CONNECT_SETTINGS")
        try {
            startActivity(settingsIntent)
            return
        } catch (_: ActivityNotFoundException) {
            // Fall through to package-specific settings or Play Store.
        }

        val packageIntent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:com.google.android.apps.healthdata")
        }
        try {
            startActivity(packageIntent)
            return
        } catch (_: ActivityNotFoundException) {
            // Fall through to Play Store.
        }

        val playStoreIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("market://details?id=com.google.android.apps.healthdata")
        }
        startActivity(playStoreIntent)
    }
}
