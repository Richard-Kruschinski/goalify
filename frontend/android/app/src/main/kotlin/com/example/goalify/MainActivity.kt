package com.example.goalify

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.goalify.services.AppBlockingForegroundService
import com.example.goalify.services.AppBlockingAccessibilityService
import com.example.goalify.services.TimerForegroundService
import android.media.AudioManager
import android.view.KeyEvent

class MainActivity : FlutterActivity() {

    private val BLOCKING_CHANNEL = "com.goalify/app_blocking"
    private val TIMER_CHANNEL = "com.goalify/timer_service"
    private val TAG = "MainActivity"

    companion object {
        // Static reference so BroadcastReceivers can invoke Flutter methods
        // even when the activity is in the background.
        @Volatile private var timerMethodChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        /**
         * Invoke a Flutter method on the timer channel from any thread.
         * Safe to call from BroadcastReceivers. Returns false if the channel
         * is not available (Flutter engine not running).
         */
        fun invokeTimerAction(method: String, arguments: Any? = null): Boolean {
            val channel = timerMethodChannel ?: return false
            mainHandler.post {
                try {
                    channel.invokeMethod(method, arguments)
                } catch (e: Exception) {
                    Log.w("MainActivity", "invokeTimerAction failed: ${e.message}")
                }
            }
            return true
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupAppBlockingChannel(flutterEngine)
        setupTimerChannel(flutterEngine)
    }

    // ---------- App Blocking Channel (unchanged) ----------

    private fun setupAppBlockingChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLOCKING_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAppBlocking" -> {
                        try {
                            val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                            Log.d(TAG, "Starting app blocking for ${blockedApps.size} apps")
                            if (!isAccessibilityServiceEnabled()) {
                                result.error("SERVICE_NOT_ENABLED", "Accessibility service is not enabled", null)
                                return@setMethodCallHandler
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                if (!hasNotificationPermission()) {
                                    result.error("NOTIFICATION_PERMISSION_DENIED", "Notification permission required", null)
                                    return@setMethodCallHandler
                                }
                            }
                            AppBlockingForegroundService.startService(this, blockedApps)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("START_ERROR", e.message, null)
                        }
                    }
                    "stopAppBlocking" -> {
                        try {
                            AppBlockingForegroundService.stopService(this)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("STOP_ERROR", e.message, null)
                        }
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            })
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "getBlockedAttemptsCount" -> {
                        result.success(AppBlockingAccessibilityService.getBlockedAttemptsCount(this))
                    }
                    "pauseMusic" -> {
                        try {
                            val fadeDurationMs = call.argument<Int>("fadeDurationMs") ?: 4000
                            val restoreDelayMs = call.argument<Int>("restoreDelayMs") ?: 800
                            pauseMusicWithFade(fadeDurationMs, restoreDelayMs) { paused ->
                                result.success(paused)
                            }
                        } catch (e: Exception) {
                            result.error("PAUSE_MUSIC_ERROR", e.message, null)
                        }
                    }
                    "isMusicPlaying" -> {
                        result.success(isMusicPlaying())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ---------- Timer Channel ----------

    private fun setupTimerChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL)
        timerMethodChannel = channel

        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startTimer" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                        TimerForegroundService.startTimer(this, data)
                        result.success(null)
                    }
                    "pauseTimer" -> {
                        TimerForegroundService.pauseTimer(this)
                        result.success(null)
                    }
                    "resumeTimer" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                        val remaining = (data["remainingSeconds"] as? Number)?.toInt() ?: 0
                        TimerForegroundService.resumeTimer(this, remaining)
                        result.success(null)
                    }
                    "stopTimer" -> {
                        TimerForegroundService.stopTimer(this)
                        result.success(null)
                    }
                    "finishTimer" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                        val message = data["message"] as? String ?: "Timer abgeschlossen"
                        TimerForegroundService.finishTimer(this, message)
                        result.success(null)
                    }
                    "updatePhase" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                        TimerForegroundService.updatePhase(this, data)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Timer channel error [${call.method}]: ${e.message}", e)
                result.error("TIMER_ERROR", e.message, null)
            }
        }
    }

    // Handle notification tap → bring app to front and navigate to timer screen
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val timerType = intent.getStringExtra("timer_type")
        if (timerType != null) {
            // Notify Flutter to navigate to the Functions tab
            invokeTimerAction("navigateToTimer", timerType)
        }
    }

    // ---------- Helpers (unchanged from before) ----------

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "${packageName}/${AppBlockingAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(serviceName)
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this, android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else true
    }

    private fun pauseMusicWithFade(
        fadeDurationMs: Int,
        restoreDelayMs: Int,
        onComplete: (Boolean) -> Unit
    ) {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            if (!audioManager.isMusicActive) {
                onComplete(false)
                return
            }
            val originalVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            if (originalVolume <= 0) {
                sendPauseMediaKey(audioManager)
                onComplete(true)
                return
            }
            val safeFadeDuration = fadeDurationMs.coerceAtLeast(300)
            val stepDelayMs = (safeFadeDuration / originalVolume).coerceAtLeast(50)
            val handler = Handler(Looper.getMainLooper())
            fun fadeStep(volume: Int) {
                if (volume > 0) {
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
                    handler.postDelayed({ fadeStep(volume - 1) }, stepDelayMs.toLong())
                    return
                }
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
                sendPauseMediaKey(audioManager)
                handler.postDelayed({
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, originalVolume, 0)
                    onComplete(true)
                }, restoreDelayMs.coerceAtLeast(0).toLong())
            }
            fadeStep(originalVolume)
        } catch (e: Exception) {
            Log.e(TAG, "pauseMusicWithFade error: ${e.message}")
            onComplete(false)
        }
    }

    private fun sendPauseMediaKey(audioManager: AudioManager) {
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE))
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE))
    }

    private fun isMusicPlaying(): Boolean {
        return try {
            (getSystemService(AUDIO_SERVICE) as AudioManager).isMusicActive
        } catch (e: Exception) {
            false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Clear static reference when activity is destroyed
        if (timerMethodChannel != null) {
            timerMethodChannel = null
        }
    }
}
