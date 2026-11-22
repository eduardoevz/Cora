package com.cora.health.mobile

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.cora.health.mobile/discreet_icon"
        private val ALIASES = mapOf(
            "coraDefault" to "com.cora.health.mobile.LauncherDefault",
            "neutralCalendar" to "com.cora.health.mobile.LauncherCalendar",
            "neutralNotes" to "com.cora.health.mobile.LauncherNotes",
            "pocketCalculator" to "com.cora.health.mobile.LauncherCalculator",
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setDiscreetIcon" -> {
                        val key = call.argument<String>("alias")
                        if (key == null || !ALIASES.containsKey(key)) {
                            result.error("INVALID_ALIAS", "Unknown discreet icon alias: $key", null)
                            return@setMethodCallHandler
                        }
                        applyDiscreetAlias(key)
                        result.success(true)
                    }
                    "getDiscreetIcon" -> {
                        result.success(readCurrentAlias())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyDiscreetAlias(targetKey: String) {
        val pm = packageManager
        for ((key, className) in ALIASES) {
            val component = ComponentName(packageName, className)
            val newState = if (key == targetKey) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            pm.setComponentEnabledSetting(
                component,
                newState,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun readCurrentAlias(): String {
        val pm = packageManager
        for ((key, className) in ALIASES) {
            val state = pm.getComponentEnabledSetting(ComponentName(packageName, className))
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                return key
            }
        }
        return "coraDefault"
    }
}
