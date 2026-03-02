package com.example.goalify

import android.content.Intent
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.goalify.services.AppBlockingForegroundService
import com.example.goalify.services.AppBlockingAccessibilityService

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "com.goalify/app_blocking"
    private val TAG = "MainActivity"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAppBlocking" -> {
                    try {
                        val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                        Log.d(TAG, "Starting app blocking for ${blockedApps.size} apps")
                        
                        // Check if accessibility service is enabled
                        if (!isAccessibilityServiceEnabled()) {
                            Log.w(TAG, "Accessibility service is not enabled")
                            result.error("SERVICE_NOT_ENABLED", "Accessibility service is not enabled", null)
                            return@setMethodCallHandler
                        }
                        
                        // Start the foreground service
                        AppBlockingForegroundService.startService(this, blockedApps)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting app blocking: ${e.message}")
                        result.error("START_ERROR", e.message, null)
                    }
                }
                
                "stopAppBlocking" -> {
                    try {
                        Log.d(TAG, "Stopping app blocking")
                        
                        // Stop the foreground service
                        AppBlockingForegroundService.stopService(this)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error stopping app blocking: ${e.message}")
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
                
                "isAccessibilityServiceEnabled" -> {
                    try {
                        val enabled = isAccessibilityServiceEnabled()
                        Log.d(TAG, "Accessibility service enabled: $enabled")
                        result.success(enabled)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error checking accessibility service: ${e.message}")
                        result.success(false)
                    }
                }
                
                "openAccessibilitySettings" -> {
                    try {
                        Log.d(TAG, "Opening accessibility settings")
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error opening accessibility settings: ${e.message}")
                        result.error("OPEN_SETTINGS_ERROR", e.message, null)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Check if our accessibility service is enabled
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "${packageName}/${AppBlockingAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        return enabledServices.contains(serviceName)
    }
}
