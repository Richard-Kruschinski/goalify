package com.example.goalify.activities

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.example.goalify.MainActivity

/**
 * Full-screen overlay activity that appears when a blocked app is accessed
 * Shows a message to remind user to stay focused
 */
class BlockedAppOverlayActivity : Activity() {

    companion object {
        private const val TAG = "BlockedAppOverlay"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "BlockedAppOverlayActivity created")
        
        // Make it fullscreen and keep it on top
        window.apply {
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
            decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
        
        // Create UI programmatically
        setContentView(createBlockedAppView())
    }

    private fun createBlockedAppView(): View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FF6B6B")) // Red background
            setPadding(48, 48, 48, 48)
            isClickable = true
            isFocusable = true
        }

        // Icon (using emoji as text for simplicity)
        val icon = TextView(this).apply {
            text = "🚫"
            textSize = 72f
            gravity = Gravity.CENTER
        }
        layout.addView(icon)

        // Title
        val title = TextView(this).apply {
            text = "App Blockiert"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }
        layout.addView(title)

        // Message
        val message = TextView(this).apply {
            text = "Diese App ist während der Fokus-Session blockiert.\nBleiben Sie konzentriert!"
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            alpha = 0.9f
            setPadding(0, 0, 0, 48)
        }
        layout.addView(message)

        // Return button
        val button = Button(this).apply {
            text = "Zurück zu Goalify"
            textSize = 16f
            setBackgroundColor(Color.WHITE)
            setTextColor(Color.parseColor("#FF6B6B"))
            setPadding(64, 32, 64, 32)
            setOnClickListener {
                Log.d(TAG, "Return button clicked")
                returnToMainApp()
            }
        }
        layout.addView(button)

        return layout
    }

    private fun returnToMainApp() {
        Log.d(TAG, "Returning to main app")
        
        // Launch main app with clear task
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        }
        startActivity(intent)
        finish()
    }

    override fun onBackPressed() {
        // Don't allow back button to escape
        Log.d(TAG, "Back button pressed - redirecting to Goalify")
        returnToMainApp()
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "Activity paused")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "Activity resumed")
        
        // Ensure UI stays visible
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Activity destroyed")
    }
}
