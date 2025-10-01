package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.openlist.mobile.config.AppConfig

/**
 * 开机启动接收器 - 处理开机启动和包更新事件
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast: $action")

        try {
            when (action) {
                Intent.ACTION_BOOT_COMPLETED,
                "android.intent.action.QUICKBOOT_POWERON",
                "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                    Log.d(TAG, "Boot completed")
                    handleBootCompleted(context)
                }
                
                Intent.ACTION_MY_PACKAGE_REPLACED,
                Intent.ACTION_PACKAGE_REPLACED -> {
                    Log.d(TAG, "Package replaced")
                    handlePackageReplaced(context, intent)
                }
                
                else -> {
                    Log.d(TAG, "Unknown action: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling boot broadcast", e)
        }
    }

    /**
     * Handle boot completed event
     */
    private fun handleBootCompleted(context: Context) {
        Log.d(TAG, "Processing boot completed event")
        
        if (!AppConfig.isStartAtBootEnabled) {
            Log.d(TAG, "Auto start is disabled, skipping service start")
            return
        }

        // Clear manual stop flag on boot since device was restarted
        AppConfig.isManuallyStoppedByUser = false
        Log.d(TAG, "Manual stop flag cleared on boot")

        Log.d(TAG, "Auto start is enabled, starting services")
        startServices(context)
    }

    /**
     * Handle package replaced event
     */
    private fun handlePackageReplaced(context: Context, intent: Intent) {
        val packageName = intent.dataString
        Log.d(TAG, "Package replaced: $packageName")
        
        if (packageName?.contains(context.packageName) == true) {
            Log.d(TAG, "Our package was replaced, checking auto-start setting")
            if (AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto-start enabled, restarting services after package update")
                startServices(context)
            } else {
                Log.d(TAG, "Auto-start disabled, not restarting services")
            }
        }
    }

    /**
     * Start all necessary services
     */
    private fun startServices(context: Context) {
        try {
            Log.d(TAG, "Preparing to start OpenListService")
            
            // Create service intent with boot flag
            val mainServiceIntent = Intent(context, OpenListService::class.java).apply {
                putExtra("started_from_boot", true)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Log.d(TAG, "Starting service as foreground service (Android O+)")
                context.startForegroundService(mainServiceIntent)
            } else {
                Log.d(TAG, "Starting service as normal service")
                context.startService(mainServiceIntent)
            }
            
            Log.d(TAG, "Service start command sent successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start services", e)
        }
    }
}
