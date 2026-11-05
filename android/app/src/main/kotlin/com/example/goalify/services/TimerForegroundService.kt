package com.example.goalify.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.goalify.MainActivity
import com.example.goalify.R
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

        // Button and status texts sent from Flutter in the app language.
        private val LABEL_KEYS = listOf("pause", "resume", "stop", "skip", "paused", "done")
        private fun labelExtra(key: String) = "label_$key"

        // Android 16 "Live Updates": promoted ongoing notifications show as a
        // live chip in the status bar and on the lock screen (Samsung Now Bar).
        // Requested in promoteToLiveUpdate().
        private const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"
        private const val API_BAKLAVA = 36

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
                val labels = data["labels"] as? Map<*, *>
                for (key in LABEL_KEYS) {
                    (labels?.get(key) as? String)?.let { putExtra(labelExtra(key), it) }
                }
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
    private val labels = mutableMapOf(
        "pause" to "Pause",
        "resume" to "Resume",
        "stop" to "Stop",
        "skip" to "Skip",
        "paused" to "Paused",
        "done" to "Done",
    )

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
        for (key in LABEL_KEYS) {
            intent.getStringExtra(labelExtra(key))?.let { labels[key] = it }
        }
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
        val message = intent?.getStringExtra(EXTRA_FINISH_MESSAGE) ?: ""
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

    /**
     * Built like the system stopwatch: the time is the title, phase and round
     * sit quietly below it, the timer's name goes into the header next to the
     * app name, and the small icon carries the tool's color.
     */
    private fun buildNotification(): Notification {
        val tapIntent = PendingIntent.getActivity(
            this, RC_TAP,
            Intent(this, MainActivity::class.java).apply {
                putExtra("timer_type", timerType)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val time = formatTime(remainingSeconds)
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(time)
            .setContentText(buildSubtitle())
            .setSubText(title)
            .setSmallIcon(timerSmallIcon())
            .setColor(timerColor())
            .setColorized(false)
            .setContentIntent(tapIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(
                if (Build.VERSION.SDK_INT >= API_BAKLAVA) "stopwatch"
                else NotificationCompat.CATEGORY_ALARM
            )
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)

        addActionButtons(builder)
        val notification = builder.build()
        if (Build.VERSION.SDK_INT < API_BAKLAVA) return notification
        return promoteToLiveUpdate(notification, if (isPaused) labels["paused"] ?: time else time)
    }

    /**
     * Android 16 Live Update: the system shows a promoted ongoing notification
     * as a live chip in the status bar and on the lock screen (Samsung's Now
     * Bar on One UI 8). Uses the platform builder, since this androidx.core
     * version has no setters for it.
     *
     * The request flag is the extra behind Notification.Builder
     * .setRequestPromotedOngoing(); that setter only exists from API 36.1,
     * while the project compiles against 36, so the extra is set directly.
     */
    @androidx.annotation.RequiresApi(API_BAKLAVA)
    private fun promoteToLiveUpdate(notification: Notification, chipText: String): Notification {
        val builder = Notification.Builder.recoverBuilder(this, notification)
            .setShortCriticalText(chipText)
        builder.extras.putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true)
        val promoted = builder.build()
        if (!loggedPromotionState) {
            loggedPromotionState = true
            Log.d(
                TAG,
                "Live Update: canPost=${notificationManager.canPostPromotedNotifications()} " +
                    "promotable=${promoted.hasPromotableCharacteristics()}"
            )
        }
        return promoted
    }

    private var loggedPromotionState = false

    /** "Focus · 1/2", or "Paused · Focus · 1/2" while paused. */
    private fun buildSubtitle(): String {
        val parts = mutableListOf<String>()
        if (isPaused) parts.add(labels["paused"] ?: "")
        if (currentPhase.isNotEmpty()) parts.add(currentPhase)
        if (totalRounds > 1 && currentRound > 0) parts.add("$currentRound/$totalRounds")
        return parts.filter { it.isNotEmpty() }.joinToString(" · ")
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
            .setContentTitle(labels["done"])
            .setContentText(message)
            .setSubText(title)
            .setSmallIcon(timerSmallIcon())
            .setColor(timerColor())
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun addActionButtons(builder: NotificationCompat.Builder) {
        if (isPaused) {
            builder.addAction(
                android.R.drawable.ic_media_play, labels["resume"],
                actionPendingIntent("resume", RC_RESUME)
            )
        } else {
            builder.addAction(
                android.R.drawable.ic_media_pause, labels["pause"],
                actionPendingIntent("pause", RC_PAUSE)
            )
        }
        builder.addAction(
            android.R.drawable.ic_menu_close_clear_cancel, labels["stop"],
            actionPendingIntent("stop", RC_STOP)
        )
        if (additionalActions.contains("skip")) {
            builder.addAction(
                android.R.drawable.ic_media_next, labels["skip"],
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
        "music" -> R.drawable.ic_notif_music
        "interval" -> R.drawable.ic_notif_interval
        else -> R.drawable.ic_notif_timer
    }

    /** The tool hues from the app: tomato, amber, green. */
    private fun timerColor(): Int = when (timerType) {
        "music" -> 0xFFD9A045.toInt()
        "interval" -> 0xFF5BB57A.toInt()
        else -> 0xFFE5534B.toInt()
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
