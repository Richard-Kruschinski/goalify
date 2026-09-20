package com.example.goalify.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.goalify.MainActivity
import com.example.goalify.receivers.TimerActionReceiver

/**
 * Foreground service that shows a live, ongoing timer notification.
 *
 * The service maintains its own countdown using startEpochMs + remainingAtStart
 * so it runs reliably even without per-second MethodChannel updates from Dart.
 *
 * Channel protocol (Flutter → this service via MethodChannel in MainActivity):
 *   startTimer(map)   – start or restart the live notification
 *   pauseTimer(null)  – pause the countdown, switch to "Paused" notification
 *   resumeTimer(map)  – resume with given remainingSeconds
 *   stopTimer(null)   – remove the notification, stop the service
 *   finishTimer(map)  – show a brief "completed" notification, then auto-dismiss
 *   updatePhase(map)  – update phase label/round/time for mid-run phase changes
 */
class TimerForegroundService : Service() {

    companion object {
        private const val TAG = "TimerFgService"
        const val CHANNEL_ID = "timer_channel"
        const val NOTIFICATION_ID = 2001

        const val ACTION_START = "com.example.goalify.TIMER_START"
        const val ACTION_PAUSE = "com.example.goalify.TIMER_PAUSE"
        const val ACTION_RESUME = "com.example.goalify.TIMER_RESUME"
        const val ACTION_STOP = "com.example.goalify.TIMER_STOP"
        const val ACTION_FINISH = "com.example.goalify.TIMER_FINISH"
        const val ACTION_UPDATE_PHASE = "com.example.goalify.TIMER_UPDATE_PHASE"

        private const val EXTRA_TIMER_ID = "timerId"
        private const val EXTRA_TIMER_TYPE = "timerType"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_REMAINING_SECONDS = "remainingSeconds"
        private const val EXTRA_TOTAL_SECONDS = "totalSeconds"
        private const val EXTRA_CURRENT_PHASE = "currentPhase"
        private const val EXTRA_CURRENT_ROUND = "currentRound"
        private const val EXTRA_TOTAL_ROUNDS = "totalRounds"
        private const val EXTRA_ADDITIONAL_ACTIONS = "additionalActions"
        private const val EXTRA_FINISH_MESSAGE = "message"

        // PendingIntent request codes
        private const val RC_TAP = 100
        private const val RC_PAUSE = 101
        private const val RC_RESUME = 102
        private const val RC_STOP = 103
        private const val RC_SKIP = 104

        fun startTimer(context: Context, data: Map<String, Any?>) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TIMER_ID, data[EXTRA_TIMER_ID] as? String ?: "timer")
                putExtra(EXTRA_TIMER_TYPE, data[EXTRA_TIMER_TYPE] as? String ?: "pomodoro")
                putExtra(EXTRA_TITLE, data[EXTRA_TITLE] as? String ?: "Timer")
                putExtra(EXTRA_REMAINING_SECONDS, (data[EXTRA_REMAINING_SECONDS] as? Number)?.toInt() ?: 0)
                putExtra(EXTRA_TOTAL_SECONDS, (data[EXTRA_TOTAL_SECONDS] as? Number)?.toInt() ?: 0)
                putExtra(EXTRA_CURRENT_PHASE, data[EXTRA_CURRENT_PHASE] as? String ?: "")
                putExtra(EXTRA_CURRENT_ROUND, (data[EXTRA_CURRENT_ROUND] as? Number)?.toInt() ?: 0)
                putExtra(EXTRA_TOTAL_ROUNDS, (data[EXTRA_TOTAL_ROUNDS] as? Number)?.toInt() ?: 0)
                val extra = data[EXTRA_ADDITIONAL_ACTIONS]
                val actions = when (extra) {
                    is List<*> -> ArrayList(extra.filterIsInstance<String>())
                    else -> ArrayList()
                }
                putStringArrayListExtra(EXTRA_ADDITIONAL_ACTIONS, actions)
            }
            startFg(context, intent)
        }

        fun pauseTimer(context: Context) {
            context.startService(Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_PAUSE
            })
        }

        fun resumeTimer(context: Context, remainingSeconds: Int) {
            context.startService(Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_RESUME
                putExtra(EXTRA_REMAINING_SECONDS, remainingSeconds)
            })
        }

        fun stopTimer(context: Context) {
            context.startService(Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_STOP
            })
        }

        fun finishTimer(context: Context, message: String) {
            context.startService(Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_FINISH
                putExtra(EXTRA_FINISH_MESSAGE, message)
            })
        }

        fun updatePhase(context: Context, data: Map<String, Any?>) {
            context.startService(Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_UPDATE_PHASE
                putExtra(EXTRA_REMAINING_SECONDS, (data[EXTRA_REMAINING_SECONDS] as? Number)?.toInt() ?: 0)
                putExtra(EXTRA_TOTAL_SECONDS, (data[EXTRA_TOTAL_SECONDS] as? Number)?.toInt() ?: 0)
                putExtra(EXTRA_CURRENT_PHASE, data[EXTRA_CURRENT_PHASE] as? String ?: "")
                putExtra(EXTRA_CURRENT_ROUND, (data[EXTRA_CURRENT_ROUND] as? Number)?.toInt() ?: 0)
                putExtra(EXTRA_TOTAL_ROUNDS, (data[EXTRA_TOTAL_ROUNDS] as? Number)?.toInt() ?: 0)
            })
        }

        private fun startFg(context: Context, intent: Intent) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    // Timer state
    private var timerId = "timer"
    private var timerType = "pomodoro"
    private var title = "Timer"
    private var totalSeconds = 0
    private var currentPhase = ""
    private var currentRound = 0
    private var totalRounds = 0
    private var additionalActions: List<String> = emptyList()

    // Countdown tracking
    private var remainingAtStart = 0
    private var startEpochMs = 0L
    private var isPaused = false

    // Current displayed remaining seconds
    private val remainingSeconds: Int
        get() = if (isPaused) {
            remainingAtStart
        } else {
            val elapsed = ((System.currentTimeMillis() - startEpochMs) / 1000).toInt()
            (remainingAtStart - elapsed).coerceAtLeast(0)
        }

    private val handler = Handler(Looper.getMainLooper())
    private val tickRunnable = object : Runnable {
        override fun run() {
            if (isPaused) return
            val remaining = remainingSeconds
            updateNotification()
            if (remaining > 0) {
                handler.postDelayed(this, 500)
            } else {
                Log.d(TAG, "Timer expired naturally")
                MainActivity.invokeTimerAction("onTimerAction", "finished")
                stopSelf()
            }
        }
    }

    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(NotificationManager::class.java)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_PAUSE -> handlePause()
            ACTION_RESUME -> handleResume(intent)
            ACTION_STOP -> handleStop()
            ACTION_FINISH -> handleFinish(intent)
            ACTION_UPDATE_PHASE -> handleUpdatePhase(intent)
        }
        return START_NOT_STICKY
    }

    private fun handleStart(intent: Intent) {
        timerId = intent.getStringExtra(EXTRA_TIMER_ID) ?: "timer"
        timerType = intent.getStringExtra(EXTRA_TIMER_TYPE) ?: "pomodoro"
        title = intent.getStringExtra(EXTRA_TITLE) ?: "Timer"
        totalSeconds = intent.getIntExtra(EXTRA_TOTAL_SECONDS, 0)
        currentPhase = intent.getStringExtra(EXTRA_CURRENT_PHASE) ?: ""
        currentRound = intent.getIntExtra(EXTRA_CURRENT_ROUND, 0)
        totalRounds = intent.getIntExtra(EXTRA_TOTAL_ROUNDS, 0)
        additionalActions = intent.getStringArrayListExtra(EXTRA_ADDITIONAL_ACTIONS) ?: emptyList()
        remainingAtStart = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 0)
        startEpochMs = System.currentTimeMillis()
        isPaused = false

        try {
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed: ${e.message}", e)
            stopSelf()
            return
        }

        handler.removeCallbacks(tickRunnable)
        handler.post(tickRunnable)
        Log.d(TAG, "Timer started: $title ($timerType), remaining: $remainingAtStart s")
    }

    private fun handlePause() {
        remainingAtStart = remainingSeconds // capture current value before stopping
        isPaused = true
        handler.removeCallbacks(tickRunnable)
        updateNotification()
        Log.d(TAG, "Timer paused at ${remainingAtStart}s")
    }

    private fun handleResume(intent: Intent?) {
        val newRemaining = intent?.getIntExtra(EXTRA_REMAINING_SECONDS, remainingAtStart) ?: remainingAtStart
        remainingAtStart = newRemaining
        startEpochMs = System.currentTimeMillis()
        isPaused = false
        handler.removeCallbacks(tickRunnable)
        handler.post(tickRunnable)
        updateNotification()
        Log.d(TAG, "Timer resumed with ${newRemaining}s remaining")
    }

    private fun handleStop() {
        handler.removeCallbacks(tickRunnable)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
        Log.d(TAG, "Timer stopped")
    }

    private fun handleFinish(intent: Intent?) {
        handler.removeCallbacks(tickRunnable)
        val message = intent?.getStringExtra(EXTRA_FINISH_MESSAGE) ?: "Timer abgeschlossen"
        val notification = buildCompletionNotification(message)
        notificationManager.notify(NOTIFICATION_ID, notification)
        // Auto-dismiss after 6 seconds
        handler.postDelayed({
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
        }, 6000)
        Log.d(TAG, "Timer finished: $message")
    }

    private fun handleUpdatePhase(intent: Intent?) {
        if (intent == null) return
        remainingAtStart = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 0)
        totalSeconds = intent.getIntExtra(EXTRA_TOTAL_SECONDS, totalSeconds)
        currentPhase = intent.getStringExtra(EXTRA_CURRENT_PHASE) ?: currentPhase
        currentRound = intent.getIntExtra(EXTRA_CURRENT_ROUND, currentRound)
        totalRounds = intent.getIntExtra(EXTRA_TOTAL_ROUNDS, totalRounds)
        startEpochMs = System.currentTimeMillis()
        isPaused = false
        handler.removeCallbacks(tickRunnable)
        handler.post(tickRunnable)
        updateNotification()
        Log.d(TAG, "Phase updated: $currentPhase, remaining: ${remainingAtStart}s")
    }

    // ------------------------------------------------------------------
    // Notification building
    // ------------------------------------------------------------------

    private fun buildNotification(): Notification {
        val tapIntent = PendingIntent.getActivity(
            this, RC_TAP,
            Intent(this, MainActivity::class.java).apply {
                putExtra("timer_type", timerType)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val contentTitle = buildTitle()
        val contentText = if (isPaused) {
            "⏸  ${formatTime(remainingSeconds)} · Pausiert"
        } else {
            "▶  ${formatTime(remainingSeconds)} verbleibend"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .setSmallIcon(timerSmallIcon())
            .setContentIntent(tapIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)

        addActionButtons(builder)
        return builder.build()
    }

    private fun buildCompletionNotification(message: String): Notification {
        val tapIntent = PendingIntent.getActivity(
            this, RC_TAP,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("✓ $title abgeschlossen")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun buildTitle(): String {
        val sb = StringBuilder(title)
        if (currentPhase.isNotEmpty()) sb.append(" · $currentPhase")
        if (totalRounds > 1 && currentRound > 0) sb.append(" ($currentRound/$totalRounds)")
        return sb.toString()
    }

    private fun addActionButtons(builder: NotificationCompat.Builder) {
        if (isPaused) {
            builder.addAction(
                android.R.drawable.ic_media_play, "Fortsetzen",
                actionPendingIntent("resume", RC_RESUME)
            )
        } else {
            builder.addAction(
                android.R.drawable.ic_media_pause, "Pause",
                actionPendingIntent("pause", RC_PAUSE)
            )
        }
        builder.addAction(
            android.R.drawable.ic_menu_close_clear_cancel, "Stop",
            actionPendingIntent("stop", RC_STOP)
        )
        if (additionalActions.contains("skip")) {
            builder.addAction(
                android.R.drawable.ic_media_next, "Überspringen",
                actionPendingIntent("skip", RC_SKIP)
            )
        }
    }

    private fun actionPendingIntent(action: String, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            this, requestCode,
            Intent(this, TimerActionReceiver::class.java).apply {
                putExtra("timer_action", action)
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

    private fun timerSmallIcon(): Int = when (timerType) {
        "music" -> android.R.drawable.ic_media_play
        "pomodoro" -> android.R.drawable.ic_lock_idle_alarm
        else -> android.R.drawable.ic_dialog_info
    }

    private fun formatTime(seconds: Int): String {
        val h = seconds / 3600
        val m = (seconds % 3600) / 60
        val s = seconds % 60
        return if (h > 0) "%02d:%02d:%02d".format(h, m, s) else "%02d:%02d".format(m, s)
    }

    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timer",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Zeigt laufende Timer"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(tickRunnable)
        Log.d(TAG, "TimerForegroundService destroyed")
    }
}
