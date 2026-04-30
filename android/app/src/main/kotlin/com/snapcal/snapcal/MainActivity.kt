package com.snapcal.snapcal

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for Android 15+ (SDK 35) compatibility.
        // This replaces the deprecated setStatusBarColor / setNavigationBarColor APIs.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
