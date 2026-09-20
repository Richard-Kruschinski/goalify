package com.example.goalify.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.goalify.MainActivity
import com.example.goalify.activities.BlockedAppOverlayActivity

/**
 * AccessibilityService to monitor foreground apps and block distracting apps
 * during focus sessions.
 */
class AppBlockingAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockingService"
        private const val PREFS_NAME = "goalify_app_blocking"
        private const val KEY_BLOCKED_ATTEMPTS = "blocked_attempts_count"
        private var isBlocking = false
        private var blockedApps = mutableSetOf<String>()
        private var blockedAttemptsCount = 0
        private var lastAttemptPackage: String? = null
        private var lastAttemptTimestampMs: Long = 0L
        
        // Static method to update blocking state from MainActivity
        fun setBlockingEnabled(enabled: Boolean, apps: List<String>) {
            isBlocking = enabled
            blockedApps.clear()
            blockedApps.addAll(apps)
            Log.d(TAG, "Blocking ${if (enabled) "ENABLED" else "DISABLED"} for ${apps.size} apps: $apps")
        }
        
        fun isBlockingEnabled(): Boolean = isBlocking

        fun getBlockedAttemptsCount(context: Context): Int {
            val persistedCount = context
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getInt(KEY_BLOCKED_ATTEMPTS, 0)

            if (persistedCount != blockedAttemptsCount) {
                blockedAttemptsCount = persistedCount
            }
            return blockedAttemptsCount
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AccessibilityService connected")
        
        // Configure the service
        val info = AccessibilityServiceInfo().apply {
            // Monitor window state changes to detect app changes
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            
            // We want all apps
            packageNames = null
            
            // Get events as soon as possible
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            
            // Don't need to wait
            notificationTimeout = 100
            
            // We need to detect app changes
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        }
        
        serviceInfo = info
        Log.d(TAG, "AccessibilityService configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) {
            return
        }
        
        Log.d(TAG, "Accessibility event: type=${event.eventType}, isBlocking=$isBlocking, blockedAppsCount=${blockedApps.size}")

        // Check the current foreground app
        val currentApp = event.packageName?.toString() ?: getForegroundApp()
        
        if (currentApp != null) {
            Log.d(TAG, "Current app: $currentApp, isBlocking=$isBlocking")
            
            if (isBlocking) {
                // Don't block our own app or system UI
                if (currentApp == "com.example.goalify" || 
                    currentApp == "com.android.systemui" ||
                    currentApp == "android" ||
                    currentApp == "com.android.launcher" ||
                    currentApp == "com.android.launcher3") {
                    Log.d(TAG, "System app allowed: $currentApp")
                    return
                }

                // Check if this app should be blocked
                if (blockedApps.contains(currentApp)) {
                    Log.d(TAG, "BLOCKING app: $currentApp")
                    blockApp(currentApp)
                } else {
                    Log.d(TAG, "App not in blocked list: $currentApp")
                }
            }
        }
    }

    private fun getForegroundApp(): String? {
        return try {
            val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
            @Suppress("DEPRECATION")
            val tasks = activityManager.getRunningTasks(1)
            if (tasks.isNotEmpty()) {
                tasks[0].topActivity?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}")
            null
        }
    }

    private fun blockApp(packageName: String) {
        try {
            maybeTrackBlockedAttempt(packageName)

            Log.d(TAG, "Launching BlockedAppOverlayActivity for $packageName")
            // Launch overlay activity to block the app
            val intent = Intent(this, BlockedAppOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("blocked_package", packageName)
            }
            startActivity(intent)
            
            // Bring our app to foreground
            bringGoalifyToForeground()
        } catch (e: Exception) {
            Log.e(TAG, "Error launching overlay: ${e.message}", e)
        }
    }

    private fun maybeTrackBlockedAttempt(packageName: String) {
        val nowMs = System.currentTimeMillis()
        val isDuplicateBurst =
            packageName == lastAttemptPackage && (nowMs - lastAttemptTimestampMs) < 1500

        if (isDuplicateBurst) {
            return
        }

        lastAttemptPackage = packageName
        lastAttemptTimestampMs = nowMs
        blockedAttemptsCount += 1

        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_BLOCKED_ATTEMPTS, blockedAttemptsCount)
            .apply()

        Log.d(TAG, "Blocked attempts tracked: $blockedAttemptsCount")
    }

    private fun bringGoalifyToForeground() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error bringing Goalify to foreground: ${e.message}", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AccessibilityService destroyed")
    }
}

