package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.openlist.mobile.server.ServerSettings

/**
 * Restores the server after boot or an app update. Runs in the `:server`
 * process; both broadcasts are exempt from background FGS start limits and
 * the specialUse type is allowed from BOOT_COMPLETED on Android 15.
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent?.action == null) return
        Log.d(TAG, "Received broadcast: ${intent.action}")

        val s = ServerSettings.get()
        val shouldStart = when (intent.action) {
            // A reboot clears a previous manual stop.
            Intent.ACTION_BOOT_COMPLETED -> s.startAtBoot
            // An update only restores a server that was running before it.
            Intent.ACTION_MY_PACKAGE_REPLACED -> s.wasRunning && !s.manuallyStopped
            else -> false
        }
        if (!shouldStart) {
            Log.d(TAG, "Auto start not required")
            return
        }
        try {
            OpenListService.sendAction(context, OpenListService.ACTION_START)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
        }
    }
}
