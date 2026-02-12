package com.example.absence_excelso

import android.content.Context
import android.location.LocationManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class SecurityCheckChannel {
    companion object {
        private const val CHANNEL = "com.example.absence_excelso/security"

        fun setupChannel(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "isDeveloperModeEnabled" -> {
                            val isDeveloperMode = isDeveloperModeEnabled(context)
                            result.success(isDeveloperMode)
                        }
                        "isMockLocationEnabled" -> {
                            val isMockLocationEnabled = isMockLocationEnabled(context)
                            result.success(isMockLocationEnabled)
                        }
                        "isDeviceRooted" -> {
                            val isRooted = isDeviceRooted()
                            result.success(isRooted)
                        }
                        else -> result.notImplemented()
                    }
                }
        }

        private fun isDeveloperModeEnabled(context: Context): Boolean {
            return try {
                val developerModeEnabled = Settings.Secure.getInt(
                    context.contentResolver,
                    Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                    0
                ) != 0
                developerModeEnabled
            } catch (e: Exception) {
                false
            }
        }

        private fun isMockLocationEnabled(context: Context): Boolean {
            return try {
                val mockLocationEnabled = Settings.Secure.getInt(
                    context.contentResolver,
                    Settings.Secure.ALLOW_MOCK_LOCATION,
                    0
                ) != 0
                mockLocationEnabled
            } catch (e: Exception) {
                false
            }
        }

        private fun isDeviceRooted(): Boolean {
            return try {
                // Check common root indicator files
                val paths = arrayOf(
                    "/system/app/Superuser.apk",
                    "/sbin/su",
                    "/system/bin/su",
                    "/system/xbin/su",
                    "/data/local/xbin/su",
                    "/data/local/bin/su",
                    "/system/sd/xbin/su",
                    "/system/bin/failsafe/su",
                    "/data/local/su",
                    "/su/bin/su"
                )

                for (path in paths) {
                    if (File(path).exists()) {
                        return true
                    }
                }

                // Check for build tags indicating rooted device
                val buildTags = android.os.Build.TAGS
                if (buildTags != null && buildTags.contains("test-keys")) {
                    return true
                }

                false
            } catch (e: Exception) {
                false
            }
        }
    }
}
