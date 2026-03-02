package com.example.goalify.activities

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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

    private val autoCloseHandler = Handler(Looper.getMainLooper())
    private val autoCloseRunnable = Runnable {
        returnToMainApp()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make it fullscreen
        window.apply {
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
        
        // Auto-close after 2 seconds and return to main app
        autoCloseHandler.postDelayed(autoCloseRunnable, 2000)
    }

    private fun createBlockedAppView(): View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FF6B6B")) // Red background
            setPadding(48, 48, 48, 48)
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
            text = "App Blocked"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }
        layout.addView(title)

        // Message
        val message = TextView(this).apply {
            text = "This app is blocked during Focus Mode.\nStay focused on your work!"
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            alpha = 0.9f
            setPadding(0, 0, 0, 48)
        }
        layout.addView(message)

        // Return button
        val button = Button(this).apply {
            text = "Return to Goalify"
            textSize = 16f
            setBackgroundColor(Color.WHITE)
            setTextColor(Color.parseColor("#FF6B6B"))
            setPadding(64, 32, 64, 32)
            setOnClickListener {
                returnToMainApp()
            }
        }
        layout.addView(button)

        return layout
    }

    private fun returnToMainApp() {
        autoCloseHandler.removeCallbacks(autoCloseRunnable)
        
        // Launch main app
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
    }

    override fun onBackPressed() {
        // Don't allow back button to escape
        returnToMainApp()
    }

    override fun onDestroy() {
        super.onDestroy()
        autoCloseHandler.removeCallbacks(autoCloseRunnable)
    }
}
