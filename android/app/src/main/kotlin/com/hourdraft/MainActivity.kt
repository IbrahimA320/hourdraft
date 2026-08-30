package com.hourdraft

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "hourdraft/storage"
    private val preferencesName = "hourdraft_storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            val key = call.argument<String>("key")
            if (key == null) {
                result.error("INVALID_ARGUMENT", "A storage key is required.", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "get" -> result.success(preferences.getString(key, null))
                "set" -> {
                    val value = call.argument<String>("value")
                    if (value == null) {
                        result.error("INVALID_VALUE", "A string storage value is required.", null)
                    } else {
                        preferences.edit().putString(key, value).apply()
                        result.success(null)
                    }
                }
                "remove" -> {
                    preferences.edit().remove(key).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}