package com.example.goalify

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.goalify.services.AppBlockingForegroundService
import com.example.goalify.services.AppBlockingAccessibilityService
import android.media.AudioManager
import android.view.KeyEvent
import android.os.Handler
import android.os.Looper

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
                        
                        // Check notification permission on Android 13+ (API 33+)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (!hasNotificationPermission()) {
                                Log.w(TAG, "Notification permission is not granted")
                                result.error("NOTIFICATION_PERMISSION_DENIED", "Notification permission is required to start foreground service", null)
                                return@setMethodCallHandler
                            }
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
                
                "pauseMusic" -> {
                    try {
                        val fadeDurationMs = call.argument<Int>("fadeDurationMs") ?: 4000
                        val restoreDelayMs = call.argument<Int>("restoreDelayMs") ?: 800
                        Log.d(TAG, "Pausing music with fade (fadeDurationMs=$fadeDurationMs, restoreDelayMs=$restoreDelayMs)")
                        pauseMusicWithFade(fadeDurationMs, restoreDelayMs) { paused ->
                            result.success(paused)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error pausing music: ${e.message}")
                        result.error("PAUSE_MUSIC_ERROR", e.message, null)
                    }
                }
                
                "isMusicPlaying" -> {
                    try {
                        val playing = isMusicPlaying()
                        result.success(playing)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error checking music status: ${e.message}")
                        result.success(false)
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
    
    /**
     * Check if notification permission is granted (Android 13+)
     */
    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // Before Android 13, notification permission is not required
            true
        }
    }
    
    /**
     * Fade out currently playing music, pause it, then restore previous volume.
     * Works with any media app that responds to media controls.
     */
    private fun pauseMusicWithFade(
        fadeDurationMs: Int,
        restoreDelayMs: Int,
        onComplete: (Boolean) -> Unit
    ) {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager

            if (!audioManager.isMusicActive) {
                Log.d(TAG, "No music is currently playing")
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
                    Log.d(TAG, "Music paused and volume restored to $originalVolume")
                    onComplete(true)
                }, restoreDelayMs.coerceAtLeast(0).toLong())
            }

            fadeStep(originalVolume)
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing music with fade: ${e.message}")
            onComplete(false)
        }
    }

    private fun sendPauseMediaKey(audioManager: AudioManager) {
        val downEvent = KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE)
        val upEvent = KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE)
        audioManager.dispatchMediaKeyEvent(downEvent)
        audioManager.dispatchMediaKeyEvent(upEvent)
    }
    
    /**
     * Check if music is currently playing
     */
    private fun isMusicPlaying(): Boolean {
        return try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            audioManager.isMusicActive
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if music is playing: ${e.message}")
            false
        }
    }
}
