package com.example.goalify.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.goalify.MainActivity
import com.example.goalify.R

/**
 * ForegroundService to keep the app blocking active during focus sessions
 * Shows a persistent notification to indicate focus mode is active
 */
class AppBlockingForegroundService : Service() {

    companion object {
        private const val TAG = "AppBlockingFgService"
        private const val CHANNEL_ID = "app_blocking_channel"
        private const val NOTIFICATION_ID = 1001
        
        const val ACTION_START = "com.example.goalify.ACTION_START_BLOCKING"
        const val ACTION_STOP = "com.example.goalify.ACTION_STOP_BLOCKING"
        const val EXTRA_BLOCKED_APPS = "blocked_apps"
        private const val EXTRA_TITLE = "notification_title"
        private const val EXTRA_TEXT = "notification_text"
        private const val EXTRA_STOP_LABEL = "stop_label"

        /** The blocker's violet from the app. */
        private const val BLOCKER_COLOR = 0xFF9D86E3.toInt()
        
        fun startService(
            context: Context,
            blockedApps: List<String>,
            title: String? = null,
            text: String? = null,
            stopLabel: String? = null,
        ) {
            val intent = Intent(context, AppBlockingForegroundService::class.java).apply {
                action = ACTION_START
                putStringArrayListExtra(EXTRA_BLOCKED_APPS, ArrayList(blockedApps))
                title?.let { putExtra(EXTRA_TITLE, it) }
                text?.let { putExtra(EXTRA_TEXT, it) }
                stopLabel?.let { putExtra(EXTRA_STOP_LABEL, it) }
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, AppBlockingForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    // Texts in the app language, sent from Flutter.
    private var title = "Focus mode active"
    private var text = "Other apps are blocked"
    private var stopLabel = "Stop"

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val blockedApps = intent.getStringArrayListExtra(EXTRA_BLOCKED_APPS) ?: emptyList()
                intent.getStringExtra(EXTRA_TITLE)?.let { title = it }
                intent.getStringExtra(EXTRA_TEXT)?.let { text = it }
                intent.getStringExtra(EXTRA_STOP_LABEL)?.let { stopLabel = it }
                startBlocking(blockedApps)
            }
            ACTION_STOP -> {
                stopBlocking()
            }
        }
        return START_NOT_STICKY
    }

    private fun startBlocking(blockedApps: List<String>) {
        Log.d(TAG, "Starting app blocking for ${blockedApps.size} apps")
        
        try {
            // Update accessibility service
            AppBlockingAccessibilityService.setBlockingEnabled(true, blockedApps)
            
            // Start foreground with notification
            val notification = createNotification()
            startForeground(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service: ${e.message}", e)
            // If we can't start foreground, stop the service
            stopSelf()
        }
    }

    private fun stopBlocking() {
        Log.d(TAG, "Stopping app blocking")
        
        // Disable blocking in accessibility service
        AppBlockingAccessibilityService.setBlockingEnabled(false, emptyList())
        
        // Stop foreground service
        stopForeground(true)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when Focus Mode is active"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        // Intent to open app when notification is tapped
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        // Intent to stop blocking
        val stopIntent = Intent(this, AppBlockingForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notif_shield)
            .setColor(BLOCKER_COLOR)
            .setShowWhen(false)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_delete,
                stopLabel,
                stopPendingIntent
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        
        // Make sure blocking is disabled
        AppBlockingAccessibilityService.setBlockingEnabled(false, emptyList())
    }
}
