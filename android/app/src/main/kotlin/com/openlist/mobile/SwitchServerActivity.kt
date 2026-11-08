package com.openlist.mobile

import android.app.Activity
import android.os.Bundle
import android.util.Log

/** Launcher shortcut that toggles the server; runs in the `:server` process. */
class SwitchServerActivity : Activity() {
    companion object {
        private const val TAG = "SwitchServerActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val action = if (OpenListService.isRunning) {
            OpenListService.ACTION_STOP
        } else {
            OpenListService.ACTION_START
        }
        Log.d(TAG, "Toggle server: $action")
        try {
            // Visible activity: foreground service start is allowed.
            OpenListService.sendAction(this, action)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to toggle server", e)
        }
        finish()
    }
}
