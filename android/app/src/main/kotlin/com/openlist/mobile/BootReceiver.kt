package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.openlist.mobile.config.AppConfig

/**
 * Boot receiver - handles device boot and package update events
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent?.action == null) return
        
        Log.d(TAG, "Received broadcast: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                handleBootCompleted(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                handlePackageReplaced(context)
            }
        }
    }

    private fun handleBootCompleted(context: Context) {
        if (!AppConfig.isStartAtBootEnabled) {
            Log.d(TAG, "Auto-start disabled, skipping")
            return
        }

        // Clear manual stop flag on boot
        AppConfig.isManuallyStoppedByUser = false
        
        Log.d(TAG, "Starting OpenList service")
        startService(context)
    }

    private fun handlePackageReplaced(context: Context) {
        if (!AppConfig.isStartAtBootEnabled) {
            Log.d(TAG, "Auto-start disabled, skipping package update restart")
            return
        }
        
        Log.d(TAG, "Starting OpenList service after package update")
        startService(context)
    }

    private fun startService(context: Context) {
        try {
            val serviceIntent = Intent(context, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "Service start command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
        }
    }
}
