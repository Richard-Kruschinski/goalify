package com.example.goalify.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.goalify.MainActivity
import com.example.goalify.services.TimerForegroundService

/**
 * BroadcastReceiver for timer notification action buttons.
 *
 * When the user presses Pause/Resume/Stop/Skip in the ongoing timer notification,
 * this receiver is called. It:
 *   1. Sends an Intent to TimerForegroundService to update the notification state
 *      immediately (so the button label flips to Pause↔Resume, etc.)
 *   2. Forwards the action to Flutter via the static MethodChannel reference
 *      in MainActivity, so the Dart timer controller can update its own state.
 *
 * This two-step approach ensures the notification looks correct immediately,
 * even if Flutter is slow to respond.
 */
class TimerActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "TimerActionReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("timer_action") ?: return
        Log.d(TAG, "Received timer action: $action")

        when (action) {
            "pause" -> {
                // Update service notification to paused state immediately
                TimerForegroundService.pauseTimer(context)
                // Tell Flutter to pause the Dart timer
                MainActivity.invokeTimerAction("onTimerAction", "pause")
            }
            "resume" -> {
                // Flutter handles resume (has the accurate remaining seconds)
                // and will call resumeTimer on the service with the correct value
                MainActivity.invokeTimerAction("onTimerAction", "resume")
            }
            "stop" -> {
                // Stop the service (removes notification) immediately
                TimerForegroundService.stopTimer(context)
                // Tell Flutter to reset
                MainActivity.invokeTimerAction("onTimerAction", "stop")
            }
            "skip" -> {
                // Flutter handles skip logic entirely (next phase, new duration)
                MainActivity.invokeTimerAction("onTimerAction", "skip")
            }
        }
    }
}
