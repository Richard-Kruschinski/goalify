package com.example.goalify.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.goalify.activities.BlockedAppOverlayActivity

/**
 * AccessibilityService to monitor foreground apps and block distracting apps
 * during focus sessions.
 */
class AppBlockingAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockingService"
        private var isBlocking = false
        private var blockedApps = mutableSetOf<String>()
        
        // Static method to update blocking state from MainActivity
        fun setBlockingEnabled(enabled: Boolean, apps: List<String>) {
            isBlocking = enabled
            blockedApps.clear()
            blockedApps.addAll(apps)
            Log.d(TAG, "Blocking ${if (enabled) "enabled" else "disabled"} for ${apps.size} apps")
        }
        
        fun isBlockingEnabled(): Boolean = isBlocking
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AccessibilityService connected")
        
        // Configure the service
        val info = AccessibilityServiceInfo().apply {
            // Monitor window state changes to detect app changes
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            
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
        if (event == null || !isBlocking) {
            return
        }

        // Only handle window state changes (app switches)
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        // Get the package name of the current app
        val packageName = event.packageName?.toString() ?: return
        
        // Don't block our own app or system UI
        if (packageName == "com.example.goalify" || 
            packageName == "com.android.systemui" ||
            packageName == "android") {
            return
        }

        // Check if this app should be blocked
        if (blockedApps.contains(packageName)) {
            Log.d(TAG, "Blocked app detected: $packageName")
            blockApp(packageName)
        }
    }

    private fun blockApp(packageName: String) {
        try {
            // Launch overlay activity to block the app
            val intent = Intent(this, BlockedAppOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("blocked_package", packageName)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error launching overlay: ${e.message}")
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
