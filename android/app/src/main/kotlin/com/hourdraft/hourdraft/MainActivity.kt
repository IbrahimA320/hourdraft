package com.example.hourdraft // ⚠️ keep this matching your existing package declaration

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "hourdraft/storage"
    private val PREFS_NAME = "hourdraft_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                when (call.method) {
                    "set" -> {
                        val value = call.argument<String>("value")
                        prefs.edit().putString(key, value).apply()
                        result.success(null)
                    }
                    "get" -> {
                        result.success(prefs.getString(key, null))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}